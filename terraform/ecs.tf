resource "aws_ecs_cluster" "meadow" {
  name = var.stack_name
  tags = var.tags
}

data "aws_acm_certificate" "meadow_cert" {
  domain = "*.${trimsuffix(data.aws_route53_zone.app_zone.name, ".")}"
}

data "aws_caller_identity" "current" {}

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
resource "aws_cloudwatch_log_group" "meadow_logs" {
  name = "/ecs/${var.stack_name}"
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
