# Two S3 buckets with public access blocks and server-side encryption

resource "aws_s3_bucket" "finance" {
  bucket_prefix = "lab-finance-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "finance" {
  bucket = aws_s3_bucket.finance.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "finance" {
  bucket = aws_s3_bucket.finance.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "app_data" {
  bucket_prefix = "lab-app-data-"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "app_data" {
  bucket = aws_s3_bucket.app_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "finance_report" {
  bucket       = aws_s3_bucket.finance.id
  key          = "annual-report.csv"
  content      = "quarter,profit\nQ1,1000\nQ2,2000\nQ3,3000\nQ4,4000"
  content_type = "text/csv"
}

resource "aws_s3_object" "app_data" {
  bucket       = aws_s3_bucket.app_data.id
  key          = "config.json"
  content      = "{\"debug\": false, \"version\": \"1.0.0\"}"
  content_type = "application/json"
}



