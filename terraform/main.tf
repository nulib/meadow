terraform {
  backend "s3" {}
}

provider "aws" {
  region = var.aws_region
}

module "rds" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "2.5.0"
  allocated_storage         = "5"
  backup_window             = "04:00-05:00"
  engine                    = "postgres"
  engine_version            = "11.10"
  final_snapshot_identifier = "meadow-final"
  identifier                = "${var.stack_name}-db"
  instance_class            = "db.t3.medium"
  maintenance_window        = "Sun:01:00-Sun:02:00"
  password                  = random_string.db_password.result
  port                      = "5432"
  username                  = "postgres"
  subnet_ids                = data.aws_subnet_ids.private_subnets.ids
  family                    = "postgres11"
  vpc_security_group_ids    = [aws_security_group.meadow_db.id]
  deletion_protection       = true

  parameters = [
    {
      name  = "client_encoding"
      value = "UTF8"
    },
  ]

  tags = var.tags
}

resource "random_string" "db_password" {
  length  = "16"
  special = "false"
}

resource "aws_s3_bucket" "meadow_ingest" {
  bucket = "${var.stack_name}-${var.environment}-ingest"
  acl    = "private"
  tags   = var.tags
}

locals {
  cors_urls = flatten([
    for hostname in concat([aws_route53_record.app_hostname.fqdn], var.additional_hostnames) : [
      "http://${hostname}",
      "https://${hostname}"
    ]
  ])
}
resource "aws_s3_bucket" "meadow_uploads" {
  bucket = "${var.stack_name}-${var.environment}-uploads"
  acl    = "private"
  tags   = var.tags

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
  acl    = "private"

  versioning {
    enabled = true
  }

  tags = var.tags
}

resource "aws_s3_bucket" "meadow_preservation_checks" {
  bucket = "${var.stack_name}-${var.environment}-preservation-checks"
  acl    = "private"
  tags   = var.tags
}

resource "aws_s3_bucket" "meadow_streaming" {
  bucket = "${var.stack_name}-${var.environment}-streaming"
  acl    = "private"
  tags   = var.tags
}

data "aws_s3_bucket" "pyramid_bucket" {
  bucket = var.pyramid_bucket
}

data "aws_s3_bucket" "migration_binary_bucket" {
  bucket = var.migration_binary_bucket
}

data "aws_s3_bucket" "migration_manifest_bucket" {
  bucket = var.migration_manifest_bucket
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
      data.aws_s3_bucket.pyramid_bucket.arn,
      data.aws_s3_bucket.migration_binary_bucket.arn,
      data.aws_s3_bucket.migration_manifest_bucket.arn,
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
    ]

    resources = [
      "${aws_s3_bucket.meadow_ingest.arn}/*",
      "${aws_s3_bucket.meadow_uploads.arn}/*",
      "${aws_s3_bucket.meadow_preservation.arn}/*",
      "${aws_s3_bucket.meadow_preservation_checks.arn}/*",
      "${data.aws_s3_bucket.pyramid_bucket.arn}/*",
      "${data.aws_s3_bucket.migration_binary_bucket.arn}/*",
      "${data.aws_s3_bucket.migration_manifest_bucket.arn}/*",
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

resource "aws_security_group" "meadow_efs_client" {
  name        = "${var.stack_name}-efs-client"
  description = "Access to Meadow EFS Working Filesystem"
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

data "aws_subnet_ids" "public_subnets" {
  vpc_id = data.aws_vpc.this_vpc.id
  filter {
    name   = "tag:SubnetType"
    values = ["public"]
  }
}

data "aws_subnet_ids" "private_subnets" {
  vpc_id = data.aws_vpc.this_vpc.id
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

resource "aws_security_group" "meadow_working_access" {
  name        = "allow_meadow_access_to_efs"
  description = "Allow Meadow access to EFS file system"
  vpc_id      = data.aws_vpc.this_vpc.id

  ingress {
    description     = "NFS from Meadow"
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.meadow.id, aws_security_group.meadow_efs_client.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_file_system" "meadow_working" {
  tags = merge(var.tags, { Name = "${var.stack_name}-working" })
}

resource "aws_efs_mount_target" "meadow_working_mount" {
  for_each        = data.aws_subnet_ids.private_subnets.ids
  file_system_id  = aws_efs_file_system.meadow_working.id
  subnet_id       = each.key
  security_groups = [aws_security_group.meadow_working_access.id]
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

resource "aws_media_convert_queue" "transcode_queue" {
  name   = var.stack_name
  status = "ACTIVE"
}

resource "aws_cloudfront_origin_access_identity" "meadow_streaming_access_identity" {
  comment = var.stack_name
}

data "aws_iam_policy_document" "meadow_streaming_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.meadow_streaming.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.meadow_streaming.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_streaming_access" {
  bucket = aws_s3_bucket.meadow_streaming.id
  policy = data.aws_iam_policy_document.meadow_streaming_bucket_policy.json
}

resource "aws_cloudfront_distribution" "meadow_streaming" {
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases          = ["${var.stack_name}-streaming.${var.dns_zone}"]
  price_class      = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.meadow_streaming.bucket_domain_name
    origin_id   = "${var.stack_name}-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.stack_name}-origin"
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      cookies {
        forward = "none"
      }

      query_string = false
      headers      = ["Origin"]
    }

  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = join("", data.aws_acm_certificate.meadow_cert.*.arn)
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "meadow_streaming_cloudfront" {
  zone_id = data.aws_route53_zone.app_zone.zone_id
  name    = "${var.stack_name}-streaming"
  type    = "CNAME"
  ttl     = "900"
  records = [aws_cloudfront_distribution.meadow_streaming.domain_name]
}
