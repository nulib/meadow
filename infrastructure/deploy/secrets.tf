data "aws_cloudformation_stack" "dc_api" {
  name = var.dcapi_stack_name
}

locals {
  api_token_secret = data.aws_cloudformation_stack.dc_api.parameters.ApiTokenSecret

  config_secrets = {
    buckets = {
      ingest                = aws_s3_bucket.meadow_ingest.bucket
      preservation          = aws_s3_bucket.meadow_preservation.bucket
      pyramid               = var.pyramid_bucket
      upload                = aws_s3_bucket.meadow_uploads.bucket
      preservation_check    = aws_s3_bucket.meadow_preservation_checks.bucket
      sitemap               = var.digital_collections_bucket
      streaming             = aws_s3_bucket.meadow_streaming.bucket
    }

    db   = {
      host            = module.rds.db_instance_address
      port            = module.rds.db_instance_port
      user            = module.rds.db_instance_username
      password        = module.rds.db_instance_password
      database        = module.rds.db_instance_username
    }

    dc = {
      base_url = var.digital_collections_url
    }

    dc_api = {
      v2 = {
        api_token_secret    = local.api_token_secret
        api_token_ttl       = 300
        base_url            = var.dc_api_v2_base
      }
    }

    ezid  = {
      password        = var.ezid_password
      shoulder        = var.ezid_shoulder
      target_base_url = var.ezid_target_base_url
      url             = "https://ezid.cdlib.org/"
      user            = var.ezid_user
    }

    geonames = {
      username        = var.geonames_username
    }

    iiif = {
      base_url        = var.iiif_server_url
      distribution_id = var.iiif_cloudfront_distribution_id
      manifest_url    = var.iiif_manifest_url
    }

    search = {
      cluster_endpoint    = var.elasticsearch_url
      access_key_id     = aws_iam_access_key.meadow_elasticsearch_access_key.id
      secret_access_key = aws_iam_access_key.meadow_elasticsearch_access_key.secret
    }

    ldap = {
      host        = var.ldap_server
      port        = var.ldap_port
      base        = var.ldap_base_dn
      user_dn     = var.ldap_bind_dn
      password    = var.ldap_bind_password
    }

    mediaconvert = {
      queue       = aws_media_convert_queue.transcode_queue.arn
      role_arn    = aws_iam_role.transcode_role.arn
    }

    nusso = {
      api_key   = var.agentless_sso_key
    }

    pipeline = {
      digester        = module.digester_function.lambda_function_arn
      exif            = module.exif_function.lambda_function_arn
      frame_extractor = module.frame_extractor_function.lambda_function_arn
      mediainfo       = module.mediainfo_function.lambda_function_arn
      mime_type       = module.mime_type_function.lambda_function_arn
      tiff            = module.pyramid_tiff_function.lambda_function_arn
    }

    streaming = {
      base_url = "https://${aws_route53_record.meadow_streaming_cloudfront.fqdn}/"
    }

    work_archiver = {
      endpoint = var.work_archiver_endpoint
    }
  }
}

resource "aws_secretsmanager_secret" "config_secrets" {
  name    = "config/meadow"
  description = "Meadow configuration secrets"
}

resource "aws_secretsmanager_secret_version" "config_secrets" {
  secret_id = aws_secretsmanager_secret.config_secrets.id
  secret_string = jsonencode(local.config_secrets)
}
