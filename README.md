# AWS IAM Least-Privilege Lab

A hands-on lab that designs, builds, and **proves** least-privilege access in AWS using Terraform.
Each job role gets exactly the permissions it needs and nothing more, and automated tests
check that every allowed action works and every forbidden one is denied.

> **Least privilege:** give every identity the minimum access required to do its job.
> A cashier gets a key to the register, not to the vault.

## Scenario

A fictional small company stores data in two S3 buckets:

| Bucket | Contents | Sensitivity |
|---|---|---|
| `finance` | Financial reports | High |
| `app-data` | Everyday application files | Normal |

Three job roles need access:

| Role | Allowed | Denied |
|---|---|---|
| **Auditor** | List and read all lab data | Any write or delete |
| **Developer** | Read/write `app-data` | Any access to `finance`; any delete |
| **Finance analyst** | Read `finance` | Everything else |

## Milestones

- [x] **0. Setup:** Terraform project, short-lived CLI credentials via `aws login`, $5/month budget guardrail (`budget.tf`)
- [x] **1. Lab resources:** two S3 buckets in us-east-2, each with AES256 encryption and all public access blocked, holding made-up sample files (`annual-report.csv` in finance, `config.json` in app-data), all in `s3.tf`
- [x] **2. Roles and policies:** Auditor, Developer, Finance analyst, each scoped to specific actions and resources (`iam.tf`). Auditor tested live by assuming the role; S3 roles tested with `aws iam simulate-custom-policy` until the buckets can be created
- [x] **3. Prove it:** `tests/check-roles.sh` runs 15 allow/deny checks across all three roles. For each check it fetches the role's live policy from AWS and evaluates it with `aws iam simulate-custom-policy`. Wrong answers are reported as FAIL, a missing AWS answer (for example, expired credentials) counts as a failure instead of a false PASS, and the script exits non-zero if anything fails
- [x] **4. Break it:** deploy an over-permissive policy and demonstrate how it could be abused (privilege escalation) — see [Finding: Developer self-escalation](#finding-developer-self-escalation-via-iamputrolepolicy)
- [x] **5. Fix it:** delete the injected policy, remove `iam:PutRolePolicy` from `iam.tf`, re-apply; all 16 checks pass and the live finance read by `lab-developer` is `403` again

## Finding: Developer self-escalation via `iam:PutRolePolicy`

> Introduced **deliberately** to demonstrate and detect a privilege-escalation path.
> Marked `INTENTIONALLY INSECURE` in `iam.tf`; fixed in Milestone 5.

**Finding.** `lab-developer` was granted `iam:PutRolePolicy` on its own role. It looks
narrow, as the role can only edit itself, but that is enough to rewrite its own permissions.

**Impact.** The Developer has no access to `finance` by design. Using this permission it
attached a new inline policy to itself granting `finance` read, then read
`annual-report.csv`. No admin credentials were used. With a broader policy the same path
leads to full account takeover, so any IAM write permission (`PutRolePolicy`,
`AttachRolePolicy`, `CreatePolicyVersion`, `PassRole`, …) is as powerful as the access it
can grant.

**Detection.** `tests/check-roles.sh` asserts `lab-developer` is denied
`iam:PutRolePolicy`, and fails loudly while the flaw is present. Building this exposed a
bug in the detector: it checked only the role's first inline policy (`PolicyNames[0]`), so
once the escalation added a second policy it missed the breach — a realistic false
negative. The script now evaluates **all** of a role's inline policies.

**Remediation (Milestone 5).** Deleted the injected policy, removed `iam:PutRolePolicy`
from `iam.tf`, and re-applied. Verified: all 16 checks pass, and the finance read that the
escalation had enabled is `403 Forbidden` again when attempted live as `lab-developer`.

**Why generic tooling missed it.** I also ran AWS IAM Access Analyzer's policy validation
(`aws accessanalyzer validate-policy`) against all three roles, and against the
over-permissive Developer policy — every run returned zero findings. `iam:PutRolePolicy`
scoped to the role's own ARN is syntactically valid and not a wildcard, so a generic
linter sees nothing wrong. The escalation is only visible to a test that encodes the
*intent* of the role ("a Developer must never be able to edit IAM"), which is exactly what
`check-roles.sh` asserts. Automated best-practice scanning and intent-specific tests are
complementary, not interchangeable.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit it
aws login --profile security-lab               # short-lived credentials, no access keys
terraform init
terraform plan                                  # preview changes
terraform apply                                 # build
terraform destroy                               # tear everything down
bash tests/check-roles.sh                       # run the allow/deny tests
```

## Security notes

- **No long-term credentials.** Auth uses temporary credentials from `aws login`; no access keys exist for this account.
- **No secrets in Git.** `*.tfstate` and `*.tfvars` are gitignored; only a `.example` template is committed.
- **Cost guardrail first.** The budget alarm was deployed before anything else.

## How this was built

I wrote the IAM roles and policies (`iam.tf`) and the S3 bucket definitions
(`s3.tf`) myself in VS Code, and ran all Terraform plans, applies, and access
tests myself. I designed the test plan and wrote the test script (`tests/check-roles.sh`)
step by step.

I used Claude (an AI assistant) as a tutor: it explained concepts, reviewed my
code and pointed out bugs, scaffolded the initial project setup (provider
config, variables, budget alarm), and handled Git commits.

## Constraints

This lab runs in an AWS **Free plan** account. Free plan accounts sit under an
AWS-managed Organization whose Service Control Policies (SCPs) block services such as
CloudTrail, GuardDuty, AWS Config, and IAM Access Analyzer. These were discovered by
reading the `explicit deny in a service control policy` errors returned by the AWS CLI.
The project focuses on IAM, which those SCPs allow, and does policy validation manually
instead of with Access Analyzer.

The SCPs also restrict regional services such as S3 to **us-east-2**, which is why the
lab deploys there. This was first misread as a total S3 ban: `simulate-principal-policy`
without a region returns `explicitDeny` for S3, and a test bucket created in us-east-2
proved the real cause. The lesson is that simulator results depend on request context
(`aws:RequestedRegion`). The tests use `simulate-custom-policy` on each role's live policy,
which checks the role's own policy separately from organization-level rules.
