locals {
  dc_base = trimsuffix(var.digital_collections_url, "/")

  config_secrets = {
    buckets = {
      derivatives        = aws_s3_bucket.meadow_derivatives.bucket
      ingest             = aws_s3_bucket.meadow_ingest.bucket
      preservation       = aws_s3_bucket.meadow_preservation.bucket
      pyramid            = var.pyramid_bucket
      upload             = aws_s3_bucket.meadow_uploads.bucket
      preservation_check = aws_s3_bucket.meadow_preservation_checks.bucket
      sitemap            = var.digital_collections_bucket
      streaming          = aws_s3_bucket.meadow_streaming.bucket
    }

    db = {
      host     = module.data_services.outputs.aurora.endpoint
      port     = module.data_services.outputs.aurora.port
      user     = local.database_user
      password = random_string.db_password.result
      database = local.database_name
    }

    dc = {
      base_url = var.digital_collections_url
    }

    ezid = {
      target_base_url = "${local.dc_base}/items/"
    }

    geonames = {
      username = var.geonames_username
    }

    honeybadger = {
      api_key     = var.honeybadger_api_key
      environment = module.core.outputs.stack.prefix
    }

    mediaconvert = {
      queue    = aws_media_convert_queue.transcode_queue.arn
      role_arn = aws_iam_role.transcode_role.arn
    }

    pipeline = {
      digester        = module.pipeline_lambda["digester"].lambda_function_arn
      exif            = module.pipeline_lambda["exif"].lambda_function_arn
      frame_extractor = module.pipeline_lambda["frame_extractor"].lambda_function_arn
      mediainfo       = module.pipeline_lambda["mediainfo"].lambda_function_arn
      mime_type       = module.pipeline_lambda["mime_type"].lambda_function_arn
      tiff            = module.pipeline_lambda["tiff"].lambda_function_arn
    }

    scheduler = {
      preservation_check = var.preservation_check_schedule
    }

    streaming = {
      base_url        = "https://${aws_route53_record.meadow_streaming_cloudfront.fqdn}/"
      distribution_id = aws_cloudfront_distribution.meadow_streaming.id
    }

    work_archiver = {
      endpoint = var.work_archiver_endpoint
    }
  }
}

resource "aws_secretsmanager_secret" "config_secrets" {
  name        = "${local.prefix}/config/${var.stack_name}"
  description = "Meadow configuration secrets"
}

resource "aws_secretsmanager_secret_version" "config_secrets" {
  secret_id     = aws_secretsmanager_secret.config_secrets.id
  secret_string = jsonencode(local.config_secrets)
}
