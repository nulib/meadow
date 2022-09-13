locals {
  actions = ["ingest-file-set", "extract-mime-type", "generate-file-set-digests",
    "extract-exif-metadata", "copy-file-to-preservation", "create-pyramid-tiff", "extract-dominant-color",
  "create-transcode-job", "generate-poster-image", "transcode-complete", "file-set-complete"]
}

resource "aws_sqs_queue" "sequins_queue" {
  for_each = toset(local.actions)
  name     = "${var.stack_name}-${each.key}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "eventbridge-notifications-1"
        Effect    = "Allow"
        Principal = { "AWS" : "*" }
        Action    = "SQS:SendMessage"
        Resource  = "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.stack_name}-${each.key}"
        Condition = {
          ArnLike = {
            "aws:SourceArn" = "arn:aws:events:${var.aws_region}:${data.aws_caller_identity.current.id}:rule/*"
          }
        }
      }
    ]
  })
}

resource "aws_cloudwatch_event_rule" "mediaconvert_state_change" {
  name        = "${var.stack_name}-mediaconvert-state-change"
  description = "Send MediaConvert state changes to Meadow"
  event_pattern = jsonencode({
    source        = ["aws.mediaconvert"]
    "detail-type" = ["MediaConvert Job State Change"]
    detail = {
      status = ["COMPLETE", "ERROR"]
      queue  = [aws_media_convert_queue.transcode_queue.arn]
    }
  })
}

resource "aws_cloudwatch_event_target" "mediaconvert_state_change_sqs" {
  rule      = aws_cloudwatch_event_rule.mediaconvert_state_change.name
  target_id = "SendToTranscodeCompleteQueue"
  arn       = aws_sqs_queue.sequins_queue["transcode-complete"].arn
}
