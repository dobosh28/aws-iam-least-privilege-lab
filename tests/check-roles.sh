#!/usr/bin/env bash

PASSED=0
FAILED=0

check() {
  local ROLE="$1"
  local ACTION="$2"
  local RESOURCE="$3"
  local EXPECTED="$4"

  #local POLICY_NAME=$(aws iam list-role-policies --profile security-lab --role-name "$ROLE" --query 'PolicyNames' --output text)
  #local POLICY=$(aws iam get-role-policy --profile security-lab --role-name "$ROLE" --policy-name "$POLICY_NAME" --query PolicyDocument --output json)

  local NAMES=$(aws iam list-role-policies --profile security-lab --role-name "$ROLE" --query 'PolicyNames' --output text)

  local DOCS=()
  local POLICY_NAME
  for POLICY_NAME in $NAMES; do
    local DOC=$(aws iam get-role-policy --profile security-lab --role-name "$ROLE" --policy-name "$POLICY_NAME" --query PolicyDocument --output json)
    DOCS+=("$DOC")
  done

  DECISION=$(aws iam simulate-custom-policy --profile security-lab \
    --policy-input-list "${DOCS[@]}" \
    --action-names "$ACTION" \
    --resource-arns "$RESOURCE" \
    --query 'EvaluationResults[0].EvalDecision' --output text)

  if [ -z "$DECISION" ]; then
    echo "ERROR: $ROLE $ACTION $RESOURCE -> no answer from AWS (logged in?)"
    FAILED=$((FAILED + 1))
    return
  fi

  if [ "$DECISION" == "allowed" ]; then
    RESULT="ALLOWED"
  else 
    RESULT="DENIED"
  fi

  if [ "$RESULT" == "$EXPECTED" ]; then
    echo "PASS: $ROLE $ACTION $RESOURCE -> $RESULT"
    PASSED=$((PASSED + 1))
  else
    echo "FAIL: $ROLE $ACTION $RESOURCE -> $RESULT (expected $EXPECTED)"
    FAILED=$((FAILED + 1))
  fi
}

check lab-auditor         iam:ListRoles   "*"                                        ALLOWED
check lab-auditor         s3:PutObject    arn:aws:s3:::lab-app-data-test/file.txt    DENIED
check lab-auditor         s3:DeleteObject arn:aws:s3:::lab-app-data-test/file.txt    DENIED

check lab-developer       s3:ListBucket   arn:aws:s3:::lab-app-data-test             ALLOWED
check lab-developer       s3:GetObject    arn:aws:s3:::lab-app-data-test/file.txt    ALLOWED
check lab-developer       s3:PutObject    arn:aws:s3:::lab-app-data-test/file.txt    ALLOWED
check lab-developer       s3:DeleteObject arn:aws:s3:::lab-app-data-test/file.txt    DENIED
check lab-developer       s3:GetObject    arn:aws:s3:::lab-finance-test/file.txt     DENIED
check lab-developer       s3:CreateBucket arn:aws:s3:::lab-finance-test              DENIED
check lab-developer       iam:ListRoles   "*"                                        DENIED
check lab-developer       iam:PutRolePolicy arn:aws:iam::060692821468:role/lab-developer  DENIED

check lab-finance-analyst s3:ListBucket   arn:aws:s3:::lab-finance-test              ALLOWED
check lab-finance-analyst s3:GetObject    arn:aws:s3:::lab-finance-test/file.txt     ALLOWED
check lab-finance-analyst s3:ListBucket   arn:aws:s3:::lab-app-data-test             DENIED
check lab-finance-analyst s3:GetObject    arn:aws:s3:::lab-app-data-test/file.txt    DENIED
check lab-finance-analyst s3:PutObject    arn:aws:s3:::lab-finance-test/file.txt     DENIED

echo ""
echo "$PASSED tests passed, $FAILED tests failed."

if [ "$FAILED" -gt 0 ]; then
  exit 1
fi