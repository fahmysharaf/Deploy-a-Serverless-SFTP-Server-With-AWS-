resource "aws_s3_bucket" "files" {
  acl    = "private"
  bucket = "${var.name}-${var.region}-${data.aws_caller_identity.current.account_id}"
  lifecycle_rule {
    prefix  = ""
    enabled = true
    noncurrent_version_expiration {
      days = 30
    }
  }
  lifecycle_rule {
    prefix  = ""
    enabled = true
    expiration {
      days = 365
    }
  }
  region = var.region
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }
  tags = {
    Name = "${var.name}-${var.region}-${data.aws_caller_identity.current.account_id}"
  }
  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "files" {
  block_public_acls       = true
  block_public_policy     = true
  bucket                  = aws_s3_bucket.files.id
  ignore_public_acls      = true
  restrict_public_buckets = true
}
