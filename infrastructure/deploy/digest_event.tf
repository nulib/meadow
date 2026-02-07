data "aws_cloudformation_stack" "fixity" {
  name = "fixity"
}

locals {
  fixity_function_arn = data.aws_cloudformation_stack.fixity.outputs["executeFixityFunctionArn"]
}

resource "aws_s3_bucket_notification" "ingest_bucket_notification" {
  bucket = aws_s3_bucket.meadow_ingest.id

  lambda_function {
    lambda_function_arn = local.fixity_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "uploads_bucket_notification" {
  bucket = aws_s3_bucket.meadow_uploads.id

  lambda_function {
    lambda_function_arn = local.fixity_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "file_sets/"
  }
}
