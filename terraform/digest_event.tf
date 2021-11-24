resource "aws_s3_bucket" "cloudtrail_events" {
  bucket = "${var.stack_name}-${var.environment}-cloudtrail-logs"
  acl    = "private"
  tags   = var.tags

  lifecycle_rule {
    id      = "expire-daily"
    enabled = true

    noncurrent_version_expiration {
      days = 1
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_events_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_events.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "acl-check"
        Effect = "Allow"
        Principal = { 
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_events.arn
      },
      {
        Sid = "write-events"
        Effect = "Allow"
        Principal = { 
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_events.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      }
    ]
  })
}

resource "aws_cloudtrail" "meadow_bucket_upload_trail" {
  name           = "${var.stack_name}-upload-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_events.id
  tags           = var.tags

  event_selector {
    read_write_type = "WriteOnly"
    include_management_events = false
    data_resource {
      type = "AWS::S3::Object"
      values = [
        "${aws_s3_bucket.meadow_ingest.arn}/",
        "${aws_s3_bucket.meadow_uploads.arn}/"
      ]
    }
  }
}

resource "aws_iam_role" "fixity_function_caller" {
  name = "${var.stack_name}-fixity-function-caller"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "${var.stack_name}-allow-fixity-function"
    policy = jsonencode({
       Version  = "2012-10-17"
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

resource "aws_cloudwatch_event_rule" "notify_fixity_function" {
  name          = "${var.stack_name}-notify-fixity-function"
  description   = "Notify fixity function when file is uploaded to certain buckets"
  tags          = var.tags
  event_pattern = jsonencode({
    source        = ["aws.s3"]
    "detail-type" = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["s3.amazonaws.com"]
      eventName = ["PutObject", "CompleteMultipartUpload"]
      requestParameters = {
        "bucketName" = [
          aws_s3_bucket.meadow_ingest.id,
          aws_s3_bucket.meadow_uploads.id
        ]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "notify_fixity_function" {
  rule      = aws_cloudwatch_event_rule.notify_fixity_function.name
  target_id = "SendNotificationToFixityStepFuntion"
  arn       = "arn:aws:states:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stateMachine:${var.fixity_function}"
  role_arn  = aws_iam_role.fixity_function_caller.arn

  input_transformer {
    input_paths = {
      bucket = "$.detail.requestParameters.bucketName",
      key = "$.detail.requestParameters.key"
    }

    input_template = "{\"Bucket\": <bucket>, \"Key\": <key>}"
  }
}
