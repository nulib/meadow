locals {
  lambda_file_md5s    = [for f in fileset(path.module, "${var.source_dir}/*.{js,json}") : filemd5(f)]
  lambda_function_md5 = md5(join("",local.lambda_file_md5s))
  module_dir          = join("/", [path.cwd, path.module])
}

resource "null_resource" "lambda_function_dependencies" {
  provisioner "local-exec" {
    command = "${local.module_dir}/patchaws"
    working_dir = var.source_dir
  }

  triggers = {
    md5 = local.lambda_function_md5
  }
}

data "archive_file" "lambda_function" {
  depends_on    = [null_resource.lambda_function_dependencies]
  type          = "zip"
  source_dir    = var.source_dir
  output_path   = "${path.module}/build/${var.source_dir}-${local.lambda_function_md5}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  description   = var.description
  filename      = data.archive_file.lambda_function.output_path
  function_name = var.function_name
  handler       = var.handler
  memory_size   = var.memory_size
  package_type  = "Zip"
  publish       = true
  role          = "arn:aws:iam::000000000000:role/meadow-lambda-role"
  runtime       = var.runtime
  timeout       = var.timeout
}
