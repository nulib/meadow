terraform {
  backend "s3" {
    key = "meadow.tfstate"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "rds" {
  source                           = "terraform-aws-modules/rds/aws"
  version                          = "4.1.2"
  allocated_storage                = var.db_size
  backup_window                    = "04:00-05:00"
  engine                           = "postgres"
  engine_version                   = "11.22"
  final_snapshot_identifier_prefix = "meadow-final"
  identifier                       = "${var.stack_name}-db"
  instance_class                   = "db.t3.medium"
  maintenance_window               = "Sun:01:00-Sun:02:00"
  password                         = random_string.db_password.result
  port                             = "5432"
  username                         = "postgres"
  subnet_ids                       = data.aws_subnets.private_subnets.ids
  family                           = "postgres11"
  vpc_security_group_ids           = [aws_security_group.meadow_db.id]
  deletion_protection              = true
  storage_encrypted                = false
  create_db_subnet_group           = true

  performance_insights_enabled            = true
  performance_insights_retention_period   = 7

  parameters = [
    {
      name         = "client_encoding",
      value        = "UTF8",
      apply_method = "pending-reboot"
    },
    {
      name         = "max_locks_per_transaction",
      value        = 1024,
      apply_method = "pending-reboot"
    }
  ]

  tags = var.tags
}

locals {
  cors_urls = flatten([
    for hostname in concat([aws_route53_record.app_hostname.fqdn], var.additional_hostnames) : [
      "http://${hostname}",
      "https://${hostname}"
    ]
  ])
}

resource "random_string" "db_password" {
  length  = "16"
  special = "false"
}

resource "aws_s3_bucket" "meadow_ingest" {
  bucket = "${var.stack_name}-${var.environment}-ingest"
  tags   = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "meadow_ingest" {
  bucket = aws_s3_bucket.meadow_ingest.id

  rule {
    id     = "30-day-expiration"
    status = "Enabled"

    filter {
      object_size_greater_than = 1
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket" "meadow_uploads" {
  bucket = "${var.stack_name}-${var.environment}-uploads"
  tags   = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "meadow_uploads" {
  bucket = aws_s3_bucket.meadow_uploads.id

  rule {
    id     = "30-day-expiration"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "meadow_uploads" {
  bucket = aws_s3_bucket.meadow_uploads.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = local.cors_urls
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "meadow_preservation" {
  bucket = "${var.stack_name}-${var.environment}-preservation"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "meadow_preservation" {
  bucket = aws_s3_bucket.meadow_preservation.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Staging Preservation Bucket
resource "aws_s3_bucket_lifecycle_configuration" "meadow_preservation_staging" {
  count  = var.environment == "s" ? 1 : 0
  bucket = aws_s3_bucket.meadow_preservation.id

  rule {
    id     = "reduced-reduncancy"

    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }
  }

  rule {
    id     = "retain-on-delete"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 1
    }
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket_intelligent_tiering_configuration" "meadow_preservation_production" {
  count  = var.environment == "p" ? 1 : 0
  bucket = aws_s3_bucket.meadow_preservation.id
  name   = "intelligent-archive"

  tiering {
    access_tier = "DEEP_ARCHIVE_ACCESS"
    days        = 180
  }
}

# Production Preservation Bucket
resource "aws_s3_bucket_lifecycle_configuration" "meadow_preservation_production" {
  count  = var.environment == "p" ? 1 : 0
  bucket = aws_s3_bucket.meadow_preservation.id

  rule {
    id = "intelligent-tiering"

    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  rule {
    id     = "retain-on-delete"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
    expiration {
      expired_object_delete_marker = true
    }
  }
}

resource "aws_s3_bucket" "meadow_preservation_checks" {
  bucket = "${var.stack_name}-${var.environment}-preservation-checks"
  tags   = var.tags
}

resource "aws_s3_bucket" "meadow_streaming" {
  bucket = "${var.stack_name}-${var.environment}-streaming"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "meadow_streaming" {
  bucket = aws_s3_bucket.meadow_streaming.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "meadow_streaming" {
  depends_on = [aws_s3_bucket_versioning.meadow_streaming]
  bucket = "${var.stack_name}-${var.environment}-streaming"

  rule {
    id = "intelligent_tiering"

    status = "Enabled"

    filter {
      prefix = ""
    }
    
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }
}

resource "aws_s3_bucket_cors_configuration" "meadow_streaming" {
  bucket = aws_s3_bucket.meadow_streaming.id

  cors_rule {
    allowed_headers = ["Authorization", "Access-Control-Allow-Origin", "Range", "*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["Access-Control-Allow-Origin", "Access-Control-Allow-Headers"]
    max_age_seconds = 3000
  }
}

data "aws_s3_bucket" "pyramid_bucket" {
  bucket = var.pyramid_bucket
}

resource "aws_s3_bucket_cors_configuration" "pyramid_bucket" {
  bucket = data.aws_s3_bucket.pyramid_bucket.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag", "Access-Control-Allow-Origin", "Access-Control-Allow-Headers"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_versioning" "pyramid_bucket" {
  bucket = data.aws_s3_bucket.pyramid_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "meadow_pyramids" {
  depends_on = [aws_s3_bucket_versioning.pyramid_bucket]
  bucket = data.aws_s3_bucket.pyramid_bucket.id

  rule {
    id = "expire_old_versions"

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    status = "Enabled"
  }
}

data "aws_s3_bucket" "digital_collections_bucket" {
  bucket = var.digital_collections_bucket
}

data "aws_iam_policy_document" "this_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:ListAllMyBuckets"
    ]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy"
    ]

    resources = [
      aws_s3_bucket.meadow_ingest.arn,
      aws_s3_bucket.meadow_uploads.arn,
      aws_s3_bucket.meadow_preservation.arn,
      aws_s3_bucket.meadow_preservation_checks.arn,
      aws_s3_bucket.meadow_streaming.arn,
      data.aws_s3_bucket.pyramid_bucket.arn,
      data.aws_s3_bucket.digital_collections_bucket.arn
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:HeadObject",
      "s3:PutObjectTagging",
      "s3:GetObjectTagging"
    ]

    resources = [
      "${aws_s3_bucket.meadow_ingest.arn}/*",
      "${aws_s3_bucket.meadow_uploads.arn}/*",
      "${aws_s3_bucket.meadow_preservation.arn}/*",
      "${aws_s3_bucket.meadow_preservation_checks.arn}/*",
      "${aws_s3_bucket.meadow_streaming.arn}/*",
      "${data.aws_s3_bucket.pyramid_bucket.arn}/*",
      "${data.aws_s3_bucket.digital_collections_bucket.arn}/*"
    ]
  }
}

resource "aws_security_group" "meadow" {
  name        = var.stack_name
  description = "The Meadow Application"
  vpc_id      = data.aws_vpc.this_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

data "aws_security_group" "stack_db_group" {
  name = "stack-${var.environment}-db-client"
}

resource "aws_security_group" "meadow_db" {
  name        = "${var.stack_name}-db"
  description = "The Meadow RDS Instance"
  vpc_id      = data.aws_vpc.this_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group_rule" "allow_meadow_db_access" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.meadow.id
  security_group_id        = aws_security_group.meadow_db.id
}

resource "aws_security_group_rule" "allow_stack_db_access" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = data.aws_security_group.stack_db_group.id
  security_group_id        = aws_security_group.meadow_db.id
}

resource "aws_security_group_rule" "allow_alb_access" {
  count             = length(local.container_ports)
  type              = "ingress"
  from_port         = element(local.container_ports, count.index)
  to_port           = element(local.container_ports, count.index)
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.meadow.id
}

data "aws_route53_zone" "app_zone" {
  name = var.dns_zone
}

resource "aws_route53_record" "app_hostname" {
  zone_id = data.aws_route53_zone.app_zone.zone_id
  name    = var.stack_name
  type    = "A"

  alias {
    name                   = aws_lb.meadow_load_balancer.dns_name
    zone_id                = aws_lb.meadow_load_balancer.zone_id
    evaluate_target_health = true
  }
}

data "aws_vpc" "this_vpc" {
  id = var.vpc_id
}

data "aws_subnets" "public_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this_vpc.id]
  }

  filter {
    name   = "tag:SubnetType"
    values = ["public"]
  }
}

data "aws_subnets" "private_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this_vpc.id]
  }

  filter {
    name   = "tag:SubnetType"
    values = ["private"]
  }
}

resource "aws_ssm_parameter" "meadow_secret_key_base" {
  name      = "/${var.stack_name}/secret_key_base"
  type      = "SecureString"
  value     = random_string.secret_key_base.result
  overwrite = true
}

resource "aws_ssm_parameter" "meadow_node_name" {
  name      = "/${var.stack_name}/node_name"
  type      = "String"
  value     = "${var.stack_name}@${aws_route53_record.app_hostname.fqdn}"
  overwrite = true
}

resource "aws_iam_role" "transcode_role" {
  name = "${var.stack_name}-transcode-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "mediaconvert.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name = "${var.stack_name}-transcode-policy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:Get*", "s3:List*"]
          Resource = ["${aws_s3_bucket.meadow_preservation.arn}/*"]
        },
        {
          Effect   = "Allow"
          Action   = ["s3:Put*"]
          Resource = ["${aws_s3_bucket.meadow_streaming.arn}/*"]
        }
      ]
    })
  }
}

data "aws_iam_policy_document" "pass_transcode_role" {
  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.transcode_role.arn]
  }

  statement {
    effect = "Allow"
    actions = [
      "mediaconvert:CreateJob",
      "mediaconvert:DescribeEndpoints"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "allow_transcode" {
  name   = "${var.stack_name}-mediaconvert-access"
  policy = data.aws_iam_policy_document.pass_transcode_role.json
}

resource "aws_media_convert_queue" "transcode_queue" {
  name   = var.stack_name
  status = "ACTIVE"

  tags = var.tags
}
