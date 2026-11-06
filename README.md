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
- [ ] **1. Lab resources:** two S3 buckets (encrypted, public access blocked) with sample files
- [x] **2. Roles and policies:** Auditor, Developer, Finance analyst, each scoped to specific actions and resources (`iam.tf`). Auditor tested live by assuming the role; S3 roles tested with `aws iam simulate-custom-policy` until the buckets can be created
- [ ] **3. Prove it:** automated tests assume each role and check an allow/deny matrix
- [ ] **4. Break it:** deploy an over-permissive policy and demonstrate how it could be abused (privilege escalation)
- [ ] **5. Fix it:** remediate, re-test, and document the findings

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # then edit it
aws login --profile security-lab               # short-lived credentials, no access keys
terraform init
terraform plan                                  # preview changes
terraform apply                                 # build
terraform destroy                               # tear everything down
```

## Security notes

- **No long-term credentials.** Auth uses temporary credentials from `aws login`; no access keys exist for this account.
- **No secrets in Git.** `*.tfstate` and `*.tfvars` are gitignored; only a `.example` template is committed.
- **Cost guardrail first.** The budget alarm was deployed before anything else.

## How this was built

I wrote the IAM roles and policies (`iam.tf`) and the S3 bucket definitions
(`s3.tf`) myself in VS Code, and ran all Terraform plans, applies, and access
tests myself.

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
