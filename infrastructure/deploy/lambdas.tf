data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.stack_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags

  inline_policy {
    name = "${var.stack_name}-allow-fixity-function"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = "states:StartExecution"
          Resource = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.fixity_function}"
        }
      ]
    })
  }
}

resource "aws_iam_role_policy_attachment" "lambda_bucket_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.this_bucket_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_log_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "digester_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "digester"
  description = "Function to calcuate the sha256 digest of an S3 object"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 1024
  timeout     = 240

  tags = merge(
    var.tags,
    {
      Name = "MeadowDigester"
    },
  )
}

module "pyramid_tiff_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "pyramid-tiff"
  description = "Function to create a pyramid tiff from an S3 object and save it to an S3 bucket"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 8192
  timeout     = 240

  environment = {
    NODE_OPTIONS        = "--max-old-space-size=8192"
    VIPS_DISC_THRESHOLD = "3500m"
  }

  tags = merge(
    var.tags,
    {
      Name = "MeadowPyramids"
    },
  )
}

module "exif_function" {
  depends_on          = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source              = "./modules/meadow_lambda"
  name                = "exif"
  description         = "Function to extract EXIF metadata from an S3 object"
  role                = aws_iam_role.lambda_role.arn
  stack_name          = var.stack_name
  ephemeral_storage   = 8192
  memory_size         = 768
  timeout             = 120
  layers = [
    "arn:aws:lambda:us-east-1:652718333417:layer:perl-5_30-layer:1",
    aws_lambda_layer_version.exiftool.arn
  ]

  environment = {
    EXIFTOOL = "/opt/bin/exiftool"
  }

  tags = merge(
    var.tags,
    {
      Name = "MeadowExif"
    },
  )
}

module "mediainfo_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "mediainfo"
  description = "Function to extract technical metadata from an A/V S3 object"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 512
  timeout     = 240
  layers      = [aws_lambda_layer_version.mediainfo.arn]
  environment = {
    MEDIAINFO_PATH = "/opt/bin/mediainfo"
  }


  tags = merge(
    var.tags,
    {
      Name = "MeadowMediaInfo"
    },
  )
}

module "mime_type_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "mime-type"
  description = "Function to extract the mime-type from an S3 object"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 512
  timeout     = 120

  tags = merge(
    var.tags,
    {
      Name = "MeadowMimeType"
    },
  )
}

module "frame_extractor_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "frame-extractor"
  description = "Function to generate a poster image with an offset from an S3 video"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 1024
  timeout     = 240
  layers      = [aws_lambda_layer_version.ffmpeg.arn]

  tags = merge(
    var.tags,
    {
      Name = "MeadowFrameExtractor"
    },
  )
}

module "execute_fixity_function" {
  depends_on  = [aws_iam_role_policy_attachment.lambda_bucket_access]
  source      = "./modules/meadow_lambda"
  name        = "execute-fixity"
  description = "Function that receives S3 upload notification and triggers fixity step function execution"
  role        = aws_iam_role.lambda_role.arn
  stack_name  = var.stack_name
  memory_size = 256
  timeout     = 60
  environment = {
    stateMachineArn = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.fixity_function}"
  }


  tags = merge(
    var.tags,
    {
      Name = "MeadowExecuteFixity"
    },
  )
}
