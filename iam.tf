resource "aws_iam_role" "auditor" {
  name = "lab-auditor"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::060692821468:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "auditor_read" {
  name = "lab-auditor-read"
  role = aws_iam_role.auditor.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["iam:List*", "iam:Get*"]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role" "developer" {
  name = "lab-developer"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::060692821468:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "developer_app_data" {
  name = "lab-developer-app-data"
  role = aws_iam_role.developer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::lab-app-data-*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "arn:aws:s3:::lab-app-data-*/*"
      }
    ]
  })
}

resource "aws_iam_role" "finance_analyst" {
  name = "lab-finance-analyst"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::060692821468:root" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "finance_analyst_read" {
  name = "lab-finance-analyst-read"
  role = aws_iam_role.finance_analyst.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:ListBucket"
        Resource = "arn:aws:s3:::lab-finance-*"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::lab-finance-*/*"
      }
    ]
  })
}
