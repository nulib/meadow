locals {
  dest_path   = abspath("${path.module}/_build")
  source_path = abspath("${path.module}/../../../priv/nodejs")
}

data "archive_file" "source" {
  type          = "zip"
  source_dir    = "${local.source_path}/${var.name}"
  excludes      = [ "node_modules" ]
  output_path   = "${local.dest_path}/${var.name}.src.zip"
}

resource "null_resource" "this_zip" {
  triggers = {
    source_code = data.archive_file.source.output_sha
  }

  provisioner "local-exec" {
    command = "docker run -v ${local.source_path}:/src -v ${local.dest_path}:/dest nulib/lambda-build ${var.name} ${data.archive_file.source.output_sha}"
  }
}

resource "aws_lambda_function" "this_lambda_function" {
  depends_on    = [ null_resource.this_zip ]
  function_name = "${var.stack_name}-${var.name}"
  filename      = "${local.dest_path}/${var.name}-deploy-${data.archive_file.source.output_sha}.zip"
  description   = var.description
  handler       = var.handler
  memory_size   = var.memory_size
  runtime       = "nodejs12.x"
  timeout       = var.timeout
  role          = var.role
  tags          = var.tags

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }

  dynamic "file_system_config" {
    for_each = var.access_point_arn != "" ? [1] : []
    content {
      arn                 = var.access_point_arn
      local_mount_path    = "/mnt/working"
    }
  }

  dynamic "vpc_config" {
    for_each = length(var.subnet_ids) > 0 ? [1] : []
    content {
      subnet_ids = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }
}

