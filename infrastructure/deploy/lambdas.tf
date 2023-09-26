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

locals {
  pipeline_lambdas = {
    digester = {
      source        = "digester"
      description   = "Function to calcuate the sha256 digest of an S3 object"
      memory        = 1024
      timeout       = 240
      tag           = "MeadowDigester"
    }

    tiff = {
      source        = "pyramid-tiff"
      description   = "Function to create a pyramid tiff from an S3 object and save it to an S3 bucket"
      memory        = 8192
      timeout       = 240
      tag           = "MeadowPyramids"
      
      environment = {
        NODE_OPTIONS        = "--max-old-space-size=8192"
        VIPS_DISC_THRESHOLD = "3500m"
      }
    }

    exif = {
      source              = "exif"
      description         = "Function to extract technical metadata from an A/V S3 object"
      ephemeral_storage   = 8192
      memory              = 768
      timeout             = 120
      tag                 = "MeadowExif"

      environment = {
        EXIFTOOL = "/opt/bin/exiftool"
      }
      
      layers = [
        "arn:aws:lambda:us-east-1:652718333417:layer:perl-5_30-layer:1",
        aws_lambda_layer_version.exiftool.arn
      ]
    }

    mediainfo = {
      source        = "mediainfo"
      description   = "Function to extract the mime-type from an S3 object"
      memory        = 512
      timeout       = 240
      tag           = "MeadowMediaInfo"

      environment = {
        MEDIAINFO_PATH = "/opt/bin/mediainfo"
      }

      layers      = [aws_lambda_layer_version.mediainfo.arn]
    }

    mime_type = {
      source        = "mime-type"
      description   = "Function to generate a poster image with an offset from an S3 video"
      memory        = 512
      timeout       = 120
      tag           = "MeadowMimeType"
    }

    frame_extractor = {
      source        = "frame-extractor"
      description   = "Function that receives S3 upload notification and triggers fixity step function execution"
      memory        = 1024
      timeout       = 240
      tag           = "MeadowFrameExtractor"
      layers        = [aws_lambda_layer_version.ffmpeg.arn]
    }

    execute_fixity = {
      source        = "execute-fixity"
      description   = "Function that receives S3 upload notification and triggers fixity step function execution"
      memory        = 256
      timeout       = 60
      tag           = "MeadowExecuteFixity"

      environment = {
        stateMachineArn = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.fixity_function}"
      }
    }
  }
}

module "pipeline_lambda" {
  for_each    = local.pipeline_lambdas
  source      = "terraform-aws-modules/lambda/aws"
  version     = "~> 3.1"
  
  function_name             = "${var.stack_name}-${each.value.source}"
  # build_in_docker           = true
  description               = each.value.description
  handler                   = "index.handler"
  ephemeral_storage_size    = contains(keys(each.value), "ephemeral_storage") ? each.value.ephemeral_storage : 512
  memory_size               = each.value.memory
  runtime                   = "nodejs18.x"
  timeout                   = each.value.timeout
  publish                   = true
  create_role               = false
  lambda_role               = aws_iam_role.lambda_role.arn
  
  environment_variables   = contains(keys(each.value), "environment") ? each.value.environment : {}
  layers                  = contains(keys(each.value), "layers") ? each.value.layers : []

  source_path = [
    {
      path = "${path.module}/../../lambdas/${each.value.source}",
      commands = [ "npm ci --only prod", ":zip" ]
    }
  ]

  tags = {
    Component = "pipeline"
    Name      = each.value.tag
  }
}
