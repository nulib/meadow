resource "aws_ecs_cluster" "meadow" {
  name = var.stack_name
  tags = var.tags
}

data "aws_acm_certificate" "meadow_cert" {
  domain = "${var.certificate_name}.${trimsuffix(data.aws_route53_zone.app_zone.name, ".")}"
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
    sid    = "cloudfront"
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = ["*"]
  }
  statement {
    sid    = "lambda"
    effect = "Allow"
    actions = [
      "lambda:GetFunction",
      "lambda:InvokeFunction"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "secretsmanager"
    effect    = "Allow"
    actions   = ["secretsmanager:Get*"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.id}:secret:config/meadow-*",
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.id}:secret:${local.prefix}/*"
    ]
  }

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

resource "aws_security_group" "meadow_load_balancer" {
  name        = "${var.stack_name}-lb"
  description = "Meadow Load Balancer Security Group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP in"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS in (Meadow)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS in (Livebook)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_iam_policy" "ecs_exec_command" {
  name = "allow-ecs-exec"
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

resource "aws_iam_role_policy_attachment" "ecs_exec_command" {
  role       = aws_iam_role.meadow_role.name
  policy_arn = data.aws_iam_policy.ecs_exec_command.arn
}

resource "aws_iam_role_policy_attachment" "meadow_transcode_passrole" {
  role       = aws_iam_role.meadow_role.name
  policy_arn = aws_iam_policy.allow_transcode.arn
}

resource "aws_cloudwatch_log_group" "meadow_logs" {
  name = "/ecs/${var.stack_name}"
  tags = var.tags
}
resource "aws_lb_target_group" "meadow_target" {
  port                 = 4000
  deregistration_delay = 30
  target_type          = "ip"
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.this_vpc.id
  tags                 = var.tags

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

resource "aws_lb_target_group" "meadow_livebook_target" {
  port                 = 8080
  deregistration_delay = 30
  target_type          = "ip"
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.this_vpc.id
  tags                 = var.tags

  health_check {
    path                = "/"
    matcher             = "200,403"
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }
}

resource "aws_lb" "meadow_load_balancer" {
  name               = "${var.stack_name}-lb"
  internal           = false
  load_balancer_type = "application"

  subnets         = data.aws_subnets.public_subnets.ids
  security_groups = [aws_security_group.meadow_load_balancer.id]
  tags            = var.tags
}

resource "aws_lb_listener" "meadow_lb_listener_http" {
  load_balancer_arn = aws_lb.meadow_load_balancer.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "meadow_lb_listener_https" {
  load_balancer_arn = aws_lb.meadow_load_balancer.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.meadow_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.meadow_target.arn
  }
}

resource "aws_lb_listener" "meadow_lb_listener_livebook" {
  load_balancer_arn = aws_lb.meadow_load_balancer.arn
  port              = 8080
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.meadow_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.meadow_livebook_target.arn
  }
}

resource "random_string" "secret_key_base" {
  length  = "64"
  special = "false"
  lower   = "false"
}
