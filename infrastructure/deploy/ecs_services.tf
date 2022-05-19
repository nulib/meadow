locals {
  container_ports = tolist([4000, 4369, 24601])

  meadow_urls = [for hostname in concat([aws_route53_record.app_hostname.fqdn], var.additional_hostnames) : "//${hostname}"]

  container_config = {
    docker_tag                      = terraform.workspace
    honeybadger_api_key             = var.honeybadger_api_key
    host_name                       = aws_route53_record.app_hostname.fqdn
    log_group                       = aws_cloudwatch_log_group.meadow_logs.name
    meadow_urls                     = join(",", local.meadow_urls)
    region                          = var.aws_region
    secret_key_base                 = random_string.secret_key_base.result
  }
}

module "meadow_task_all" {
  source           = "./modules/meadow_task"
  container_config = local.container_config
  cpu              = 2048
  db_pool_size     = 100
  meadow_processes = "all"
  memory           = 4096
  name             = "all"
  role_arn         = aws_iam_role.meadow_role.arn
  stack_name       = var.stack_name
  tags             = var.tags
}

resource "aws_ecs_service" "meadow_all" {
  name                              = "meadow"
  cluster                           = aws_ecs_cluster.meadow.id
  task_definition                   = module.meadow_task_all.task_definition.arn
  desired_count                     = 1
  enable_execute_command            = true
  health_check_grace_period_seconds = 600
  launch_type                       = "FARGATE"
  depends_on                        = [aws_lb.meadow_load_balancer]
  platform_version                  = "1.4.0"

  load_balancer {
    target_group_arn = aws_lb_target_group.meadow_target.arn
    container_name   = "meadow"
    container_port   = 4000
  }

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets          = data.aws_subnets.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}
