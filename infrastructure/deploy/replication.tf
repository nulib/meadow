provider "aws" {
  alias  = "west"
  region = var.replication_region
}

resource "aws_iam_role" "replication_role" {
  # Only create the role in production env
  count = var.environment == "p" ? 1 : 0
  name  = "${var.stack_name}-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "s3.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.stack_name}-replication-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
          Resource = ["${aws_s3_bucket.meadow_preservation.arn}"]
        },
        {
          Effect   = "Allow"
          Action   = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl", "s3:GetObjectVersionTagging"]
          Resource = ["${aws_s3_bucket.meadow_preservation.arn}/*"]
        },
        {
          Effect   = "Allow"
          Action   = ["s3:ReplicateObject", "s3:ReplicateDelete", "s3:ReplicateTags"]
          Resource = ["${aws_s3_bucket.meadow_preservation_replica[count.index].arn}/*"]
        }
      ]
    })
  }
}

resource "aws_s3_bucket" "meadow_preservation_replica" {
  count    = var.environment == "p" ? 1 : 0
  provider = aws.west
  bucket   = "${var.stack_name}-${var.environment}-preservation-replica-${var.replication_region}"

  tags = var.tags
}

resource "aws_s3_bucket_versioning" "meadow_preservation_replica" {
  count    = var.environment == "p" ? 1 : 0
  provider = aws.west
  bucket   = aws_s3_bucket.meadow_preservation_replica[count.index].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_replication_configuration" "east_to_west" {
  count  = var.environment == "p" ? 1 : 0
  role   = aws_iam_role.replication_role[count.index].arn
  bucket = aws_s3_bucket.meadow_preservation.id

  rule {
    id     = "preservation-replica"
    status = "Enabled"

    filter {
      prefix = ""
    }

    delete_marker_replication {
      status = "Enabled"
    }

    destination {
      bucket        = aws_s3_bucket.meadow_preservation_replica[count.index].arn
      storage_class = "DEEP_ARCHIVE"
    }
  }

  lifecycle {
    ignore_changes = all
  }
}
