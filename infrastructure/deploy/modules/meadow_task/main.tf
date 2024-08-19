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
}

data "aws_ecr_repository" "meadow" {
  name = "meadow"
}

locals {
  container_vars = merge(
    var.container_config,
    {
      db_pool_size          = var.db_pool_size,
      db_queue_interval     = var.db_queue_interval,
      db_queue_target       = var.db_queue_target,
      docker_repository     = data.aws_ecr_repository.meadow.repository_url,
      livebook_bucket       = var.livebook_shared_bucket,
      name                  = var.name,
      processes             = var.meadow_processes
    }
  )
}

data "template_file" "this_container_definitions" {
  template = file("task-definitions/meadow_app.json")
  vars = local.container_vars
}
