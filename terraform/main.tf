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
  parameters = [
    {
      name  = "client_encoding"
      value = "UTF8"
    }
  ]
}

resource "random_string" "db_password" {
  length  = "16"
  special = "false"
}


data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = "${data.aws_vpc.default_vpc.id}"
}
