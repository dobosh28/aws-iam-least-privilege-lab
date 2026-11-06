variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Name of the AWS CLI profile to use (set up with `aws configure sso`)"
  type        = string
  default     = "security-lab"
}

variable "alert_email" {
  description = "Email address that receives billing and security alerts"
  type        = string
}

variable "monthly_budget_usd" {
  description = "Monthly spend limit that triggers a billing alert"
  type        = string
  default     = "5"
}
