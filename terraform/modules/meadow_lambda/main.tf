locals {
  dest_path   = "${path.module}/_build"
  source_path = "${path.module}/../../../priv/nodejs"
}

data "archive_file" "source" {
  type          = "zip"
  source_dir    = "${local.source_path}/${var.name}"
  excludes      = [ "node_modules" ]
  output_path   = "${local.dest_path}/${var.name}.src.zip"
}

data "external" "this_zip" {
  program = ["${path.module}/build_lambda.sh"]
  query = {
    name = var.name
    source_sha = data.archive_file.source.output_sha
    source_path = local.source_path
    dest_path = local.dest_path
  }
}

resource "aws_lambda_function" "this_lambda_function" {
  function_name = "${var.stack_name}-${var.name}"
  filename      = data.external.this_zip.result.zip
  description   = var.description
  handler       = var.handler
  memory_size   = var.memory_size
  runtime       = "nodejs14.x"
  timeout       = var.timeout
  role          = var.role
  tags          = var.tags
  layers        = var.layers

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }
}

