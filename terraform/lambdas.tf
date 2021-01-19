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
    sid       = "efslist"
    effect    = "Allow"
    actions   = [
      "elasticfilesystem:DescribeAccessPoints"
    ]
    resources = ["*"]
  }

  statement {
    sid       = "efsaccess"
    effect    = "Allow"
    actions   = [
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

