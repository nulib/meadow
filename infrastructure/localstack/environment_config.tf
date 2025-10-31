locals {
  secrets = {
    "config/meadow" = {
      buckets = {
        ingest                = "test-ingest"
        preservation          = "test-preservation"
        preservation_check    = "test-preservation-checks"
        pyramid               = "test-pyramids"
        sitemap               = "test-sitemaps"
        streaming             = "test-streaming"
        upload                = "test-upload"
      }

      db = {
        database    = "postgres"
        host        = "localhost"
        port        = 5432
        user        = "postgres"
        password    = "d0ck3r"
      }

      dc = {
        base_url = "https://dc.dev.library.northwestern.edu/"
      }

      dc_api = {
        v2 = {
          api_token_secret    = "TEST_SECRET"
          api_token_ttl       = 300
          base_url            = "http://dcapi-test.northwestern.edu"
        }
        iiif_distribution_id = null
      }

      geonames = {
        username = "nul_rdc"
      }

      iiif = {
        base_url          = "http://localhost:8184/iiif/3/"
        distribution_id   = null
        manifest_url      = "http://test-pyramids.s3.localhost.localstack.cloud:4566/public/"
      }

      logging = {
        log_group = aws_cloudwatch_log_group.meadow_ai_metrics.name
      }

      mediaconvert = {
        queue       = "arn:aws:mediaconvert:::queues/Default"
        role_arn    = "arn:aws:iam:::role/service-role/MediaConvert_Default_Role"
      }

      streaming = {
        base_url          = "https://test-streaming-url/"
        distribution_id   = "Z7Q9N4L3X8P5J2"
      }

      work_archiver = {
        endpoint = null
      }

    }

    "infrastructure/ezid" = {
      password          = "mockpassword"
      shoulder          = "ark:/12345/nu1"
      target_base_url   = "https://devbox.library.northwestern.edu:3333/items/"
      url               = "http://localhost:3944"
      user              = "mockuser"
    }

    "infrastructure/iiif" = {
      base = "http://localhost/"
      v2   = "http://localhost/iiif/2"
      v3   = "http://localhost/iiif/3"
    }

    "infrastructure/index" = {
      endpoint = "http://localhost:9200"
    }

    # "infrastructure/inference" = {
    #   endpoints = {
    #     endpoint = "https://bedrock-runtime.us-east-1.amazonaws.com/model/cohere.embed-multilingual-v3/invoke"
    #     name = "cohere.embed-multilingual-v3"
    #   }

    # }

    "infrastructure/nusso" = {
      api_key   = "test-sso-key"
      base_url  = "https://northwestern-dev.apigee.net/agentless-websso/"
    }
  }
}

resource "aws_secretsmanager_secret" "config_secrets" {
  for_each = local.secrets
  name     = each.key
}

resource "aws_secretsmanager_secret_version" "config_secrets" {
  for_each = local.secrets
  secret_id = aws_secretsmanager_secret.config_secrets[each.key].id
  secret_string = jsonencode(each.value)
}
