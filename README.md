# AWS Security Baseline

A hardened AWS account baseline built with Terraform, following AWS security best practices
and the CIS AWS Foundations Benchmark. This is the foundation for an automated threat
detection and response pipeline (Project 2).

## Milestones

- [ ] **0. Account setup (manual):** root MFA, IAM Identity Center admin user, CLI via SSO
- [x] **1. Billing guardrail:** AWS Budgets alert at $5/month (`budget.tf`)
- [ ] **2. Audit logging:** CloudTrail (all regions) to an encrypted, locked-down S3 bucket
- [ ] **3. Configuration monitoring:** AWS Config recorder + CIS-aligned managed rules
- [ ] **4. Threat detection:** GuardDuty enabled
- [ ] **5. Account hardening:** IAM password policy, S3 Block Public Access (account-wide), EBS default encryption
- [ ] **6. Verification:** Prowler scan before and after, with results documented

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit it
aws sso login --profile security-lab
terraform init
terraform plan
terraform apply
```

To tear everything down: `terraform destroy`

## Security notes

- No credentials are stored in this repo. Auth uses short-lived SSO credentials via a named CLI profile.
- `*.tfstate` and `*.tfvars` are gitignored.
