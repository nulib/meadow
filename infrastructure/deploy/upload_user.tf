data "aws_iam_policy_document" "upload_bucket_access" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets"
    ]
    resources = ["arn:aws:s3:::*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:DeleteObjectTagging",
      "s3:DeleteObjectVersion",
      "s3:ListBucketVersions",
      "s3:PutObjectVersionTagging",
      "s3:ListBucket",
      "s3:DeleteObjectVersionTagging",
      "s3:PutObject",
      "s3:GetObjectAcl",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:PutObjectAcl",
      "s3:GetObjectVersion"
    ]

    resources = concat([
      aws_s3_bucket.meadow_ingest.arn,
      aws_s3_bucket.meadow_uploads.arn,
      aws_s3_bucket.meadow_preservation_checks.arn,
      "${aws_s3_bucket.meadow_ingest.arn}/*",
      "${aws_s3_bucket.meadow_uploads.arn}/*",
      "${aws_s3_bucket.meadow_preservation_checks.arn}/*"
    ], var.transcription_bucket != "" ? [
      "arn:aws:s3:::${var.transcription_bucket}",
      "arn:aws:s3:::${var.transcription_bucket}/*"
    ] : [])
  }
}

resource "aws_iam_policy" "upload_bucket_policy" {
  name        = "${var.stack_name}-upload-policy"
  description = "Read-write access to Meadow ingest and upload buckets"
  policy      = data.aws_iam_policy_document.upload_bucket_access.json
}

resource "aws_iam_group" "upload_group" {
  name = "${var.stack_name}-uploaders"
}

resource "aws_iam_group_policy_attachment" "upload_group_policy" {
  group      = aws_iam_group.upload_group.name
  policy_arn = aws_iam_policy.upload_bucket_policy.arn
}

resource "aws_iam_user" "upload_user" {
  name = "${var.stack_name}-uploader"
  tags = var.tags
}

resource "aws_iam_user_group_membership" "upload_user_group_membership" {
  user   = aws_iam_user.upload_user.name
  groups = [aws_iam_group.upload_group.name]
}

resource "aws_iam_access_key" "upload_user_access_key" {
  user = aws_iam_user.upload_user.name
}
