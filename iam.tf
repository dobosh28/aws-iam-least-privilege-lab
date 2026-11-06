resource "aws_iam_role" "auditor" {
  name = "lab-auditor"
  assume_role_policy = jsonencode({
	Version = "2012-10-17"
	Statement = [{
		Effect = "Allow"
		Principal = { AWS = "arn:aws:iam::060692821468:root" }
		Action = "sts:AssumeRole"
	}]
  })
}