locals {
  container_ports = tolist([4000, 4369, 24601])

  meadow_urls = [for hostname in concat([aws_route53_record.app_hostname.fqdn], var.additional_hostnames) : "//${hostname}"]

  container_config = {
    agentless_sso_key          = var.agentless_sso_key
    digital_collections_bucket = var.digital_collections_bucket
    digital_collections_url    = var.digital_collections_url
    database_url               = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_username}"
    docker_tag                 = terraform.workspace
    elasticsearch_key          = aws_iam_access_key.meadow_elasticsearch_access_key.id
    elasticsearch_secret       = aws_iam_access_key.meadow_elasticsearch_access_key.secret
    elasticsearch_url          = var.elasticsearch_url
    ezid_password              = var.ezid_password
    ezid_shoulder              = var.ezid_shoulder
    ezid_target_base_url       = var.ezid_target_base_url
    ezid_user                  = var.ezid_user
    geonames_username          = var.geonames_username
    honeybadger_api_key        = var.honeybadger_api_key
    host_name                  = aws_route53_record.app_hostname.fqdn
    iiif_manifest_url          = var.iiif_manifest_url
    iiif_server_url            = var.iiif_server_url
    ingest_bucket              = aws_s3_bucket.meadow_ingest.bucket
    log_group                  = aws_cloudwatch_log_group.meadow_logs.name
    meadow_urls                = join(",", local.meadow_urls)
    preservation_bucket        = aws_s3_bucket.meadow_preservation.bucket
    pyramid_bucket             = var.pyramid_bucket
    region                     = var.aws_region
    secret_key_base            = random_string.secret_key_base.result
    upload_bucket              = aws_s3_bucket.meadow_uploads.bucket
    ldap_server                = var.ldap_server
    ldap_base_dn               = var.ldap_base_dn
    ldap_port                  = var.ldap_port
    ldap_bind_dn               = var.ldap_bind_dn
    ldap_bind_password         = var.ldap_bind_password
    preservation_check_bucket  = aws_s3_bucket.meadow_preservation_checks.bucket
    streaming_bucket           = aws_s3_bucket.meadow_streaming.bucket
    streaming_url              = "https://${aws_route53_record.meadow_streaming_cloudfront.fqdn}/"
    mediaconvert_queue         = aws_media_convert_queue.transcode_queue.arn
    mediaconvert_role          = aws_iam_role.transcode_role.arn
  }
}

module "meadow_task_all" {
  source           = "./modules/meadow_task"
  container_config = local.container_config
  cpu              = 2048
  db_pool_size     = 100
  db_queue_target  = 1000
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
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_web" {
  source           = "./modules/meadow_task"
  container_config = local.container_config
  cpu              = 512
  meadow_processes = "web"
  memory           = 1024
  name             = "web"
  role_arn         = aws_iam_role.meadow_role.arn
  stack_name       = var.stack_name
  tags             = var.tags
}

resource "aws_ecs_service" "meadow_web" {
  name                              = "meadow-web"
  cluster                           = aws_ecs_cluster.meadow.id
  task_definition                   = module.meadow_task_web.task_definition.arn
  desired_count                     = 0
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
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}

module "meadow_task_workers" {
  source           = "./modules/meadow_task"
  container_config = local.container_config
  cpu              = 1024
  db_pool_size     = 50
  db_queue_target  = 1000
  meadow_processes = "basic,pipeline"
  memory           = 2048
  name             = "workers"
  role_arn         = aws_iam_role.meadow_role.arn
  stack_name       = var.stack_name
  tags             = var.tags
}

resource "aws_ecs_service" "meadow_workers" {
  name             = "meadow-workers"
  cluster          = aws_ecs_cluster.meadow.id
  task_definition  = module.meadow_task_workers.task_definition.arn
  desired_count    = 0
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  lifecycle {
    ignore_changes = [desired_count]
  }

  network_configuration {
    subnets          = data.aws_subnet_ids.private_subnets.ids
    security_groups  = [aws_security_group.meadow.id]
    assign_public_ip = false
  }

  tags = var.tags
}
