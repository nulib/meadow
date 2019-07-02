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
    docker_tag          = "${terraform.workspace}"
    secret_key_base     = "${random_string.secret_key_base.result}"
    database_url        = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_username}"
    region              = "${var.aws_region}"
    log_group           = "${aws_cloudwatch_log_group.meadow_logs.name}"
    honeybadger_api_key = "${var.honeybadger_api_key}"
  }
}

resource "aws_ecs_service" "meadow" {
  name            = "meadow"
  cluster         = "${aws_ecs_cluster.meadow.id}"
  task_definition = "${aws_ecs_task_definition.meadow_app.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = ["aws_alb.meadow_load_balancer"]

  load_balancer {
    target_group_arn = "${aws_alb_target_group.meadow_targets.arn}"
    container_name   = "meadow-app"
    container_port   = 4000
  }

  network_configuration {
    subnets          = "${data.aws_subnet_ids.default_subnets.ids}"
    security_groups  = ["${aws_security_group.meadow.id}"]
    assign_public_ip = true
  }

  tags = "${var.tags}"
}

resource "aws_alb_target_group" "meadow_targets" {
  port        = 4000
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"
  tags        = "${var.tags}"
}

resource "aws_alb" "meadow_load_balancer" {
  name               = "${var.stack_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.meadow_alb.id}"]
  subnets            = "${data.aws_subnet_ids.default_subnets.ids}"
  tags               = "${var.tags}"
}

resource "aws_lb_listener" "meadow_alb_listener" {
  load_balancer_arn = "${aws_alb.meadow_load_balancer.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_alb_target_group.meadow_targets.arn}"
  }
}

resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}
