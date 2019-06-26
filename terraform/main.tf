module "rds-postgres" {
  source         = "QuiNovas/rds-postgres/aws"
  version        = "2.0.0"
  database_name  = "meadow"
  instance_class = "db.t3.micro"
  name           = "${var.stack_name}-db"
  subnet_ids     = []
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnets" {
  vpc_id = "${data.aws_vpc.default_vpc.id}"
}
