locals {
  container_ports = tolist([4000, 4369, 8080, 24601])

  meadow_urls = [for hostname in concat([aws_route53_record.app_hostname.fqdn], var.additional_hostnames) : "//${hostname}"]
  canonical_hostname = coalesce(var.canonical_hostname, aws_route53_record.app_hostname.fqdn)
  container_config = {
    docker_tag                      = terraform.workspace
    honeybadger_api_key             = var.honeybadger_api_key
    host_name                       = local.canonical_hostname
    internal_host_name              = "${var.stack_name}.${data.aws_service_discovery_dns_namespace.internal_dns_zone.name}"
    log_group                       = aws_cloudwatch_log_group.meadow_logs.name
    meadow_urls                     = join(",", local.meadow_urls)
    region                          = var.aws_region
    secret_key_base                 = random_string.secret_key_base.result
    secrets_path                    = local.prefix
  }
}

module "meadow_task_all" {
  source                    = "./modules/meadow_task"
  container_config          = local.container_config
  cpu                       = 2048
  db_pool_size              = 100
  db_queue_target           = 500
  db_queue_interval         = 2500
  livebook_shared_bucket    = var.livebook_shared_bucket
  meadow_processes          = "all"
  memory                    = 4096
  name                      = "all"
  role_arn                  = aws_iam_role.meadow_role.arn
  stack_name                = var.stack_name
  tags                      = var.tags
}

data "aws_service_discovery_dns_namespace" "internal_dns_zone" {
  name = "internal.${var.dns_zone}"
  type = "DNS_PRIVATE"
}

resource "aws_service_discovery_service" "meadow" {
  name = "meadow"

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.internal_dns_zone.id
    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  tags = var.tags
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

  service_registries {
    registry_arn = aws_service_discovery_service.meadow.arn
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.meadow_target.arn
    container_name   = "meadow"
    container_port   = 4000
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.meadow_livebook_target.arn
    container_name   = "livebook"
    container_port   = 8080
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

resource "aws_appautoscaling_target" "ecs_target" {
  count              = var.environment == "p" ? 1 : 0
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.meadow.name}/${aws_ecs_service.meadow_all.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Scheduled action to scale UP at 7:15 AM Central
resource "aws_appautoscaling_scheduled_action" "scale_up" {
  count              = var.environment == "p" ? 1 : 0
  name               = "scale-up-to-2-tasks"
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  timezone           = "America/Chicago"
  schedule           = "cron(15 7 ? * MON-FRI *)"  

  scalable_target_action {
    min_capacity = 2
    max_capacity = 2
  }
}

# Scheduled action to scale DOWN at 6:00 PM Central
resource "aws_appautoscaling_scheduled_action" "scale_down" {
  count              = var.environment == "p" ? 1 : 0
  name               = "scale-down-to-1-task"
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  timezone           = "America/Chicago"
  schedule           = "cron(0 18 ? * MON-FRI *)"  

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }
}
