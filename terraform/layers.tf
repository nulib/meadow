resource "aws_lambda_layer_version" "ffmpeg" {
  s3_bucket           = "nul-public"
  s3_key              = "ffmpeg.zip"
  layer_name          = "ffmpeg"
  compatible_runtimes = ["nodejs14.x"]
  description         = "FFMPEG runtime for nodejs lambdas"
}

resource "aws_lambda_layer_version" "mediainfo" {
  s3_bucket           = "nul-public"
  s3_key              = "mediainfo_lambda_layer.zip"
  layer_name          = "mediainfo"
  compatible_runtimes = ["nodejs14.x"]
  description         = "mediainfo binaries for nodejs lambdas from https://mediaarea.net/en/MediaInfo/Download/Lambda"
}
