resource "aws_cloudwatch_log_group" "stream_authorizer_lambda_logs" {
  name = "/aws/lambda/${var.stack_name}-stream-authorizer"
}

data "aws_iam_policy_document" "stream_authorizer_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy" "basic_lambda_execution" {
  name = "AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "stream_authorizer_role" {
  name               = "${var.stack_name}-stream-authorizer"
  assume_role_policy = data.aws_iam_policy_document.stream_authorizer_assume_role.json
}

resource "aws_iam_policy" "stream_authorizer_elasticsearch_access" {
  name = "${var.stack_name}-stream-authorizer-elasticsearch-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "es:ESHttpGet"
        Effect   = "Allow"
        Sid      = ""
        Resource = "arn:aws:es:*:${data.aws_caller_identity.current.id}:domain/*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "stream_authorizer_elasticsearch_access" {
  role       = aws_iam_role.stream_authorizer_role.name
  policy_arn = aws_iam_policy.stream_authorizer_elasticsearch_access.arn
}

resource "aws_iam_role_policy_attachment" "stream_authorizer_basic_execution_role" {
  role       = aws_iam_role.stream_authorizer_role.name
  policy_arn = data.aws_iam_policy.basic_lambda_execution.arn
}

locals {
  source_sha = sha1(join("", [for f in fileset(path.module, "../../lambdas/stream-authorizer/*.{js,json}") : sha1(file(f))]))
}

resource "null_resource" "node_modules" {
  triggers = {
    source = local.source_sha
  }

  provisioner "local-exec" {
    command     = "npm install --only=prod --no-bin-links"
    working_dir = template_dir.function_source.destination_dir
  }
}

resource "template_dir" "function_source" {
  source_dir      = "${path.module}/../../lambdas/stream-authorizer/"
  destination_dir = "${path.module}/build"

  vars = {
    allowed_referers = "(devbox|digitalcollections|meadow|dc)\\.(rdc(-staging)?\\.)?library\\.northwestern\\.edu"
    elastic_search   = var.elasticsearch_url
  }
}

data "archive_file" "stream_authorizer_lambda" {
  depends_on  = [null_resource.node_modules]
  type        = "zip"
  source_dir  = template_dir.function_source.destination_dir
  output_path = "${path.module}/package/${local.source_sha}.zip"
}

resource "aws_lambda_function" "stream_authorizer" {
  filename      = data.archive_file.stream_authorizer_lambda.output_path
  function_name = "${var.stack_name}-stream-authorizer"
  role          = aws_iam_role.stream_authorizer_role.arn
  handler       = "index.handler"
  runtime       = "nodejs14.x"
  memory_size   = 128
  timeout       = 5
  publish       = true
}

resource "aws_lambda_permission" "allow_edge_invocation" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stream_authorizer.arn
  qualifier     = aws_lambda_function.stream_authorizer.version
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.meadow_streaming.arn

  lifecycle {
    create_before_destroy = true
  }
}
