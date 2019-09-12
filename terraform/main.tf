terraform {
  backend "s3" {}
}

provider "aws" {
  region = "${var.aws_region}"
}

module "rds" {
  source                    = "terraform-aws-modules/rds/aws"
  version                   = "2.0.0"
  allocated_storage         = "5"
  backup_window             = "04:00-05:00"
  engine                    = "postgres"
  engine_version            = "11.2"
  final_snapshot_identifier = "meadow-final"
  identifier                = "${var.stack_name}-db"
  instance_class            = "db.t3.micro"
  maintenance_window        = "Sun:01:00-Sun:02:00"
  password                  = "${random_string.db_password.result}"
  port                      = "5432"
  username                  = "postgres"
  subnet_ids                = "${data.aws_subnet_ids.default_subnets.ids}"
  family                    = "postgres11"
  vpc_security_group_ids    = ["${aws_security_group.meadow_db.id}"]

  parameters = [
    {
      name  = "client_encoding"
      value = "UTF8"
    },
  ]

  tags = "${var.tags}"
}

resource "random_string" "db_password" {
  length  = "16"
  special = "false"
}

resource "aws_s3_bucket" "meadow_ingest" {
  bucket = "${var.stack_name}-${var.environment}-ingest"
  acl    = "private"
  tags   = "${var.tags}"
}

resource "aws_s3_bucket" "meadow_uploads" {
  bucket = "${var.stack_name}-${var.environment}-uploads"
  acl    = "private"
  tags   = "${var.tags}"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT"]
    allowed_origins = ["http://${aws_route53_record.app_hostname.fqdn}"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

data "aws_iam_policy_document" "this_bucket_access" {
  statement {
    effect    = "Allow"
    actions   = ["s3:ListAllMyBuckets"]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      "${aws_s3_bucket.meadow_ingest.arn}",
      "${aws_s3_bucket.meadow_uploads.arn}",
    ]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${aws_s3_bucket.meadow_ingest.arn}/*",
      "${aws_s3_bucket.meadow_uploads.arn}/*",
    ]
  }
}

resource "aws_security_group" "meadow" {
  name        = "${var.stack_name}"
  description = "The Meadow Application"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_security_group" "meadow_db" {
  name        = "${var.stack_name}-db"
  description = "The Meadow RDS Instance"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.tags}"
}

resource "aws_security_group_rule" "allow_meadow_db_access" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.meadow.id}"
  security_group_id        = "${aws_security_group.meadow_db.id}"
}

resource "aws_security_group_rule" "allow_alb_access" {
  count             = "${length(local.container_ports)}"
  type              = "ingress"
  from_port         = "${element(local.container_ports, count.index)}"
  to_port           = "${element(local.container_ports, count.index)}"
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.meadow.id}"
}

data "aws_route53_zone" "app_zone" {
  name = "${var.dns_zone}"
}

resource "aws_route53_record" "app_hostname" {
  zone_id = "${data.aws_route53_zone.app_zone.zone_id}"
  name    = "${var.stack_name}"
  type    = "A"

  alias {
    name                   = "${aws_alb.meadow_load_balancer.dns_name}"
    zone_id                = "${aws_alb.meadow_load_balancer.zone_id}"
    evaluate_target_health = true
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = "${data.aws_vpc.default_vpc.id}"
}

resource "aws_ssm_parameter" "meadow_secret_key_base" {
  name      = "/${var.stack_name}/secret_key_base"
  type      = "SecureString"
  value     = "${random_string.secret_key_base.result}"
  overwrite = true
}

resource "aws_ssm_parameter" "meadow_node_name" {
  name      = "/${var.stack_name}/node_name"
  type      = "String"
  value     = "${var.stack_name}@${aws_route53_record.app_hostname.fqdn}"
  overwrite = true
}
