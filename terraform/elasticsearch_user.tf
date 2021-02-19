resource "aws_iam_user" "meadow_elasticsearch_user" {
  name = "${var.stack_name}-es-access"
  path = "/system/"
}

resource "aws_iam_access_key" "meadow_elasticsearch_access_key" {
  user = aws_iam_user.meadow_elasticsearch_user.name
}

data "aws_iam_policy_document" "meadow_elasticsearch_access" {
  statement {
    effect    = "Allow"
    actions   = [
      "es:ESHttpGet",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpDelete"
    ]
    resources = ["arn:aws:es:*:${data.aws_caller_identity.current.id}:domain/*"]
  }
}

resource "aws_iam_user_policy" "meadow_elasticsearch_policy" {
  name   = "${var.stack_name}-meadow-elasticsearch-access"
  user   = aws_iam_user.meadow_elasticsearch_user.name
  policy = data.aws_iam_policy_document.meadow_elasticsearch_access.json
}
