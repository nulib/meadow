resource "aws_ecs_cluster" "meadow" {
  name = "${var.stack_name}"
}

resource "aws_ecs_task_definition" "meadow_app" {
  family                   = "${var.stack_name}-app"
  container_definitions    = "${data.template_file.container_definitions.rendered}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
}

data "template_file" "container_definitions" {
  template = "${file("task-definitions/meadow_app.json")}"
  vars = {
    docker_tag      = "${terraform.workspace}"
    secret_key_base = "${random_string.secret_key_base.result}"
    database_url    = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_name}"
  }
}

resource "aws_ecs_service" "meadow" {
  name            = "meadow"
  cluster         = "${aws_ecs_cluster.meadow.id}"
  task_definition = "${aws_ecs_task_definition.meadow_app.arn}"
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = "${aws_lb_target_group.app_load_balancer.arn}"
    container_name   = "meadow-app"
    container_port   = 4000
  }
}

resource "aws_lb_target_group" "app_load_balancer" {
  port        = 4000
  target_type = "ip"
  protocol    = "HTTP"
  vpc_id      = "${data.aws_vpc.default_vpc.id}"
}

resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}

