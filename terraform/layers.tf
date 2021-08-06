resource "aws_lambda_layer_version" "ffmpeg" {
  s3_bucket           = "nul-public"
  s3_key              = "ffmpeg.zip"
  layer_name          = "ffmpeg"
  compatible_runtimes = ["nodejs14.x"]
  description         = "FFMPEG runtime for nodejs lambdas"
}
