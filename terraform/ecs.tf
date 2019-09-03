resource "aws_ecs_cluster" "meadow" {
  name = "${var.stack_name}"
  tags = "${var.tags}"
}

data "aws_iam_role" "task_execution_role" {
  name = "ecsTaskExecutionRole"
}

data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "meadow_role" {
  name               = "${var.stack_name}-task-role"
  assume_role_policy = "${data.aws_iam_policy_document.ecs_assume_role.json}"
  tags               = "${var.tags}"
}

resource "aws_iam_policy" "this_bucket_policy" {
  name   = "meadow-bucket-access"
  policy = "${data.aws_iam_policy_document.this_bucket_access.json}"
}

resource "aws_iam_role_policy_attachment" "bucket_role_access" {
  role       = "${aws_iam_role.meadow_role.name}"
  policy_arn = "${aws_iam_policy.this_bucket_policy.arn}"
}

resource "aws_ecs_task_definition" "meadow_app" {
  family                   = "${var.stack_name}-app"
  container_definitions    = "${data.template_file.container_definitions.rendered}"
  task_role_arn            = "${aws_iam_role.meadow_role.arn}"
  execution_role_arn       = "${data.aws_iam_role.task_execution_role.arn}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  tags                     = "${var.tags}"
}

resource "aws_cloudwatch_log_group" "meadow_logs" {
  name = "/ecs/${var.stack_name}"
  tags = "${var.tags}"
}

data "template_file" "container_definitions" {
  template = "${file("task-definitions/meadow_app.json")}"

  vars = {
    database_url        = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_username}"
    docker_tag          = "${terraform.workspace}"
    honeybadger_api_key = "${var.honeybadger_api_key}"
    host_name           = "${aws_route53_record.app_hostname.fqdn}"
    ingest_bucket       = "${aws_s3_bucket.meadow_ingest.bucket}"
    log_group           = "${aws_cloudwatch_log_group.meadow_logs.name}"
    region              = "${var.aws_region}"
    secret_key_base     = "${random_string.secret_key_base.result}"
    upload_bucket       = "${aws_s3_bucket.meadow_uploads.bucket}"
  }
}

locals {
  container_ports = "${list(4000, 4369, 24601)}"
  listener_ports = "${list(80, 4369, 24601)}"
}

resource "aws_ecs_service" "meadow" {
  name            = "meadow"
  cluster         = "${aws_ecs_cluster.meadow.id}"
  task_definition = "${aws_ecs_task_definition.meadow_app.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = ["aws_alb.meadow_load_balancer"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.meadow_targets.0.arn}"
    container_name   = "meadow-app"
    container_port   = "${element(local.container_ports, 0)}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.meadow_targets.1.arn}"
    container_name   = "meadow-app"
    container_port   = "${element(local.container_ports, 1)}"
  }

  load_balancer {
    target_group_arn = "${aws_alb_target_group.meadow_targets.2.arn}"
    container_name   = "meadow-app"
    container_port   = "${element(local.container_ports, 2)}"
  }

  network_configuration {
    subnets          = "${data.aws_subnet_ids.default_subnets.ids}"
    security_groups  = ["${aws_security_group.meadow.id}"]
    assign_public_ip = true
  }

  tags = "${var.tags}"
}

resource "aws_alb_target_group" "meadow_targets" {
  count       = "${length(local.container_ports)}"
  port        = "${element(local.container_ports, count.index)}"
  target_type = "ip"
  protocol    = "TCP"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"
  tags        = "${var.tags}"

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

resource "aws_alb" "meadow_load_balancer" {
  name               = "${var.stack_name}-alb"
  internal           = false
  load_balancer_type = "network"

  subnets = "${data.aws_subnet_ids.default_subnets.ids}"
  tags    = "${var.tags}"
}

resource "aws_lb_listener" "meadow_alb_listener" {
  count             = "${length(local.listener_ports)}"
  load_balancer_arn = "${aws_alb.meadow_load_balancer.arn}"
  port              = "${element(local.listener_ports, count.index)}"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${element(aws_alb_target_group.meadow_targets.*.arn, count.index)}"
  }
}

resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}
