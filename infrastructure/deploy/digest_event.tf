resource "aws_s3_bucket_notification" "ingest_bucket_notification" {
  bucket = aws_s3_bucket.meadow_ingest.id
  depends_on = [aws_lambda_permission.allow_invoke_from_ingest_bucket]

  lambda_function {
    lambda_function_arn = module.execute_fixity_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_s3_bucket_notification" "uploads_bucket_notification" {
  bucket = aws_s3_bucket.meadow_uploads.id
  depends_on = [aws_lambda_permission.allow_invoke_from_uploads_bucket]

  lambda_function {
    lambda_function_arn = module.execute_fixity_function.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "file_sets/"
  }
}

resource "aws_lambda_permission" "allow_invoke_from_ingest_bucket" {
  statement_id  = "AllowExecutionFromIngestBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.execute_fixity_function.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.meadow_ingest.arn
}

resource "aws_lambda_permission" "allow_invoke_from_uploads_bucket" {
  statement_id  = "AllowExecutionFromUploadsBucket"
  action        = "lambda:InvokeFunction"
  function_name = module.execute_fixity_function.lambda_function_arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.meadow_uploads.arn
}