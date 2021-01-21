data "aws_iam_role" "task_execution_role" {
  name = "ecsTaskExecutionRole"
}

resource "aws_ecs_task_definition" "this_task_definition" {
  family                   = "${var.stack_name}-${var.name}"
  container_definitions    = data.template_file.this_container_definitions.rendered
  task_role_arn            = var.role_arn
  execution_role_arn       = data.aws_iam_role.task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  tags                     = var.tags

  volume {
    name = "meadow-working"
    efs_volume_configuration {
      file_system_id = var.file_system_id
    }
  }
}

locals {
  container_vars = merge(
    var.container_config,
    {
      cpu_reservation       = var.cpu * 0.9765625,
      db_pool_size          = var.db_pool_size,
      memory_reservation    = var.memory * 0.9765625,
      name                  = var.name,
      processes             = var.meadow_processes
    }
  )
}

data "template_file" "this_container_definitions" {
  template = file("task-definitions/meadow_app.json")
  vars = local.container_vars
}
