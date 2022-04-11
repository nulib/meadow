module "work-archiver" {
  source = "git::https://github.com/nulib/work-archiver.git//work-archiver?ref=2618-cloud-dev-env"
  # source = "../../../work-archiver/work-archiver"

  elasticsearch_endpoint          = "http://elasticsearch:9200"
  email_access_policy_arn         = aws_iam_policy.email_access.arn
  elasticsearch_access_policy_arn = aws_iam_policy.index_read_access.arn
  environment                     = "local"
  index                           = "meadow"
  sender_email                    = "work-archiver@northwestern.edu"
}

data "aws_iam_policy_document" "index_read_access" {
  statement {
    effect    = "Allow"
    actions   = ["es:ESHttpGet"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "index_read_access" {
  name   = "elasticsearch-read"
  policy = data.aws_iam_policy_document.index_read_access.json
}

data "aws_iam_policy_document" "email_access" {
  statement {
    effect    = "Allow"
    actions   = ["ses:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "email_access" {
  name   = "send-email"
  policy = data.aws_iam_policy_document.email_access.json
}


