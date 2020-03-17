resource "aws_ecs_cluster" "meadow" {
  name = var.stack_name
  tags = var.tags
}

data "aws_acm_certificate" "meadow_cert" {
  domain = "${var.stack_name}.${trimsuffix(data.aws_route53_zone.app_zone.name, ".")}"
}

data "aws_caller_identity" "current" {}

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

data "aws_iam_policy_document" "meadow_role_permissions" {
  statement {
    sid    = "sns"
    effect = "Allow"
    actions = [
      "sns:CreateTopic",
      "sns:GetSubscriptionAttributes",
      "sns:ListSubscriptions",
      "sns:ListTopics",
      "sns:Publish",
      "sns:SetSubscriptionAttributes",
      "sns:Subscribe",
      "sns:Unsubscribe"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "sqs"
    effect = "Allow"
    actions = [
      "sqs:CreateQueue",
      "sqs:DeleteMessage",
      "sqs:DeleteMessageBatch",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
      "sqs:SendMessageBatch",
      "sqs:SetQueueAttributes"
    ]
    resources = ["arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

resource "aws_iam_role" "meadow_role" {
  name               = "${var.stack_name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = var.tags
}

resource "aws_iam_policy" "meadow_role_policy" {
  name   = "${var.stack_name}-policy"
  policy = data.aws_iam_policy_document.meadow_role_permissions.json
}

resource "aws_iam_role_policy_attachment" "meadow_role_policy" {
  role       = aws_iam_role.meadow_role.id
  policy_arn = aws_iam_policy.meadow_role_policy.arn
}

resource "aws_iam_policy" "this_bucket_policy" {
  name   = "meadow-bucket-access"
  policy = data.aws_iam_policy_document.this_bucket_access.json
}

resource "aws_iam_role_policy_attachment" "bucket_role_access" {
  role       = aws_iam_role.meadow_role.name
  policy_arn = aws_iam_policy.this_bucket_policy.arn
}

resource "aws_ecs_task_definition" "meadow_app" {
  family                   = "${var.stack_name}-app"
  container_definitions    = data.template_file.container_definitions.rendered
  task_role_arn            = aws_iam_role.meadow_role.arn
  execution_role_arn       = data.aws_iam_role.task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 2048
  memory                   = 4096
  tags                     = var.tags
}

resource "aws_cloudwatch_log_group" "meadow_logs" {
  name = "/ecs/${var.stack_name}"
  tags = var.tags
}

data "template_file" "container_definitions" {
  template = file("task-definitions/meadow_app.json")

  vars = {
    database_url         = "ecto://${module.rds.this_db_instance_username}:${module.rds.this_db_instance_password}@${module.rds.this_db_instance_endpoint}/${module.rds.this_db_instance_username}"
    docker_tag           = terraform.workspace
    elasticsearch_key    = aws_iam_access_key.meadow_elasticsearch_access_key.id
    elasticsearch_secret = aws_iam_access_key.meadow_elasticsearch_access_key.secret
    elasticsearch_url    = var.elasticsearch_url
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

locals {
  container_ports = list(4000, 4369, 24601)
}

resource "aws_ecs_service" "meadow" {
  name            = "meadow"
  cluster         = aws_ecs_cluster.meadow.id
  task_definition = aws_ecs_task_definition.meadow_app.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  depends_on      = [aws_alb.meadow_load_balancer]

  dynamic "load_balancer" {
    for_each = local.container_ports
    iterator = port
    content {
      target_group_arn = aws_alb_target_group.meadow_targets[port.key].arn
      container_name   = "meadow-app"
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

resource "aws_alb_target_group" "meadow_targets" {
  count       = length(local.container_ports)
  port        = element(local.container_ports, count.index)
  target_type = "ip"
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.this_vpc.id
  tags        = var.tags

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

resource "aws_alb" "meadow_load_balancer" {
  name               = "${var.stack_name}-alb"
  internal           = false
  load_balancer_type = "network"

  subnets = data.aws_subnet_ids.public_subnets.ids
  tags    = var.tags
}

resource "aws_lb_listener" "meadow_alb_listener_http" {
  load_balancer_arn = aws_alb.meadow_load_balancer.arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.meadow_targets.0.arn
  }
}

resource "aws_lb_listener" "meadow_alb_listener_https" {
  load_balancer_arn = aws_alb.meadow_load_balancer.arn
  port              = 443
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.meadow_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.meadow_targets.0.arn
  }
}

resource "aws_lb_listener" "meadow_alb_listener_epmd" {
  load_balancer_arn = aws_alb.meadow_load_balancer.arn
  port              = 4369
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.meadow_targets.1.arn
  }
}

resource "aws_lb_listener" "meadow_alb_listener_remote_iex" {
  load_balancer_arn = aws_alb.meadow_load_balancer.arn
  port              = 24601
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.meadow_targets.2.arn
  }
}

resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}
