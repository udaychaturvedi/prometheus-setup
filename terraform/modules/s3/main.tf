variable "create_bucket" { type = bool }
variable "project_slug" {}
variable "tags" { type = map(string) }

resource "aws_s3_bucket" "backup" {
  count  = var.create_bucket ? 1 : 0
  bucket = "${var.project_slug}-backup"
  force_destroy = true

  tags = merge(var.tags, {
    Name = "${var.project_slug}-backup"
  })
}

resource "aws_s3_bucket_versioning" "versioning" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sse" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.backup[0].id

  rule {
    id     = "expire_old_backups"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

output "backup_bucket_name" {
  value = var.create_bucket ? aws_s3_bucket.backup[0].bucket : null
}
