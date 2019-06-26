resource "aws_ecs_cluster" "meadow" {
  name = "${var.stack_name}"
}

resource "aws_ecs_task_definition" "meadow_app" {
  family                = "${var.stack_name}-app"
  container_definitions = "${data.template_file.container_definitions.rendered}"
}

data "template_file" "container_definitions" {
  template = "${file("task-definitions/meadow_app.json")}"
  vars = {
    docker_tag      = "${terraform.workspace}"
    secret_key_base = "${random_string.secret_key_base.result}"
    database_url    = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_name}"
  }
}


resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}

