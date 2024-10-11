module "digester_function" {
  source = "./modules/localstack_lambda"

  description   = "Function to tag an S3 object with its md5 checksum"
  function_name = "digest-tag"
  handler       = "index.handler"
  memory_size   = 1024
  runtime       = "nodejs14.x"
  source_dir    = "${path.module}/lambdas/digest-tag"
  timeout       = 120
}
