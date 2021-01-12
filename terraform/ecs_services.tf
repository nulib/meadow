locals {
  container_ports = list(4000, 4369, 24601)
  container_config = {
    agentless_sso_key    = var.agentless_sso_key
    digital_collections_url =  var.digital_collections_url
    database_url         = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_username}"
    docker_tag           = terraform.workspace
    elasticsearch_key    = aws_iam_access_key.meadow_elasticsearch_access_key.id
    elasticsearch_secret = aws_iam_access_key.meadow_elasticsearch_access_key.secret
    elasticsearch_url    = var.elasticsearch_url
    ezid_password        = var.ezid_password
    ezid_shoulder        = var.ezid_shoulder
    ezid_target_base_url = var.ezid_target_base_url
    ezid_user            = var.ezid_user
    geonames_username    = var.geonames_username
    honeybadger_api_key  = var.honeybadger_api_key
    host_name            = aws_route53_record.app_hostname.fqdn
    iiif_manifest_url    = var.iiif_manifest_url
    iiif_server_url      = var.iiif_server_url
    ingest_bucket        = aws_s3_bucket.meadow_ingest.bucket
    log_group            = aws_cloudwatch_log_group.meadow_logs.name
    preservation_bucket  = aws_s3_bucket.meadow_preservation.bucket
    pyramid_bucket       = var.pyramid_bucket
    region               = var.aws_region
    secret_key_base      = random_string.secret_key_base.result
    upload_bucket        = aws_s3_bucket.meadow_uploads.bucket
    ldap_server          = var.ldap_server
    ldap_base_dn         = var.ldap_base_dn
    ldap_port            = var.ldap_port
    ldap_bind_dn         = var.ldap_bind_dn
    ldap_bind_password   = var.ldap_bind_password
  }
}

module "meadow_task_all" {
  source              = "./modules/meadow_task"
  container_config    = local.container_config
  cpu                 = 2048
  file_system_id      = aws_efs_file_system.meadow_working.id
  meadow_processes    = "all"
  memory              = 4096
  name                = "all"
  role_arn            = aws_iam_role.meadow_role.arn
  stack_name          = var.stack_name
  tags                = var.tags
}

resource "aws_ecs_service" "meadow_all" {
  name                                = "meadow-all"
  cluster                             = aws_ecs_cluster.meadow.id
  task_definition                     = module.meadow_task_all.task_definition.arn
  desired_count                       = 1
  health_check_grace_period_seconds   = 600
  launch_type                         = "FARGATE"
  depends_on                          = [aws_alb.meadow_load_balancer]
  platform_version                    = "1.4.0"

  dynamic "load_balancer" {
    for_each = local.container_ports
    iterator = port
    content {
      target_group_arn = aws_alb_target_group.meadow_targets[port.key].arn
      container_name   = "meadow-all"
      container_port   = port.value
    }
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_web" {
  source              = "./modules/meadow_task"
  container_config    = local.container_config
  cpu                 = 512
  file_system_id      = aws_efs_file_system.meadow_working.id
  meadow_processes    = "web"
  memory              = 1024
  name                = "web"
  role_arn            = aws_iam_role.meadow_role.arn
  stack_name          = var.stack_name
  tags                = var.tags
}

resource "aws_ecs_service" "meadow_web" {
  name                                = "meadow-web"
  cluster                             = aws_ecs_cluster.meadow.id
  task_definition                     = module.meadow_task_web.task_definition.arn
  desired_count                       = 0
  health_check_grace_period_seconds   = 600
  launch_type                         = "FARGATE"
  depends_on                          = [aws_alb.meadow_load_balancer]
  platform_version                    = "1.4.0"

  dynamic "load_balancer" {
    for_each = local.container_ports
    iterator = port
    content {
      target_group_arn = aws_alb_target_group.meadow_targets[port.key].arn
      container_name   = "meadow-web"
      container_port   = port.value
    }
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_workers" {
  source              = "./modules/meadow_task"
  container_config    = local.container_config
  cpu                 = 1024
  file_system_id      = aws_efs_file_system.meadow_working.id
  meadow_processes    = "basic,pipeline.ingest_file_set,pipeline.copy_file_to_preservation,pipeline.file_set_complete"
  memory              = 2048
  name                = "workers"
  role_arn            = aws_iam_role.meadow_role.arn
  stack_name          = var.stack_name
  tags                = var.tags
}

resource "aws_ecs_service" "meadow_workers" {
  name                                = "meadow-workers"
  cluster                             = aws_ecs_cluster.meadow.id
  task_definition                     = module.meadow_task_workers.task_definition.arn
  desired_count                       = 0
  launch_type                         = "FARGATE"
  platform_version                    = "1.4.0"

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_digests" {
  source              = "./modules/meadow_task"
  container_config    = local.container_config
  cpu                 = 2048
  file_system_id      = aws_efs_file_system.meadow_working.id
  meadow_processes    = "pipeline.generate_file_set_digests"
  memory              = 4096
  name                = "digests"
  role_arn            = aws_iam_role.meadow_role.arn
  stack_name          = var.stack_name
  tags                = var.tags
}

resource "aws_ecs_service" "meadow_digests" {
  name                                = "meadow-digests"
  cluster                             = aws_ecs_cluster.meadow.id
  task_definition                     = module.meadow_task_digests.task_definition.arn
  desired_count                       = 0
  launch_type                         = "FARGATE"
  platform_version                    = "1.4.0"

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_tiffs" {
  source              = "./modules/meadow_task"
  container_config    = local.container_config
  cpu                 = 2048
  file_system_id      = aws_efs_file_system.meadow_working.id
  meadow_processes    = "pipeline.generate_file_set_tiffs"
  memory              = 4096
  name                = "tiffs"
  role_arn            = aws_iam_role.meadow_role.arn
  stack_name          = var.stack_name
  tags                = var.tags
}

resource "aws_ecs_service" "meadow_tiffs" {
  name                                = "meadow-tiffs"
  cluster                             = aws_ecs_cluster.meadow.id
  task_definition                     = module.meadow_task_tiffs.task_definition.arn
  desired_count                       = 0
  launch_type                         = "FARGATE"
  platform_version                    = "1.4.0"

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

