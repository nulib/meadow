resource "aws_efs_access_point" "meadow_working_access_point" {
  file_system_id    = aws_efs_file_system.meadow_working.id
  tags              = var.tags

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/working"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = 777
    }
  }
}

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

data "aws_iam_policy_document" "lambda_access_point_policy_document" {
  statement {
    sid       = "ec2networking"
    effect    = "Allow"
    actions   = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "efslist"
    effect    = "Allow"
    actions   = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeMountTargets"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "efsaccess"
    effect    = "Allow"
    actions   = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite"
    ]
    resources = [aws_efs_file_system.meadow_working.arn]
  }
}

resource "aws_iam_policy" "lambda_access_point_policy" {
  name = "${var.stack_name}-lambda-working-access"
  policy = data.aws_iam_policy_document.lambda_access_point_policy_document.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.stack_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_working_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_access_point_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_bucket_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.this_bucket_policy.arn
}

module "digester_function" {
  depends_on    = [ aws_iam_role_policy_attachment.lambda_bucket_access ]
  source        = "./modules/meadow_lambda"
  name          = "digester"
  description   = "Function to calcuate the sha256 digest of an S3 object"
  role          = aws_iam_role.lambda_role.arn
  stack_name    = var.stack_name
  memory_size   = 1024
  timeout       = 60

  tags          = var.tags
}

module "pyramid_tiff_function" {
  depends_on    = [ aws_iam_role_policy_attachment.lambda_bucket_access ]
  source        = "./modules/meadow_lambda"
  name          = "pyramid-tiff"
  description   = "Function to create a pyramid tiff from an S3 object and save it to an S3 bucket"
  role          = aws_iam_role.lambda_role.arn
  stack_name    = var.stack_name
  memory_size   = 8192
  timeout       = 600

  environment = {
    TMPDIR                = "/mnt/working"
    VIPS_DISC_THRESHOLD   = "4g"
  }

  access_point_arn   = aws_efs_access_point.meadow_working_access_point.arn
  subnet_ids         = data.aws_subnet_ids.private_subnets.ids
  security_group_ids = [aws_security_group.meadow_efs_client.id]

  tags          = var.tags
}

module "exif_function" {
 depends_on    = [ aws_iam_role_policy_attachment.lambda_bucket_access ]
 source        = "./modules/meadow_lambda"
 name          = "exif"
 description   = "Function to extract EXIF metadata from an S3 object"
 role          = aws_iam_role.lambda_role.arn
 stack_name    = var.stack_name
 memory_size   = 4096
 timeout       = 600

 environment = {
    TMPDIR   = "/mnt/working"
  }

  access_point_arn   = aws_efs_access_point.meadow_working_access_point.arn
  subnet_ids         = data.aws_subnet_ids.private_subnets.ids
  security_group_ids = [aws_security_group.meadow_efs_client.id]

 tags          = var.tags
}