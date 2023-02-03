data "aws_acm_certificate" "wildcard_cert" {
  domain        = "*.${trimsuffix(data.aws_route53_zone.app_zone.name, ".")}"
  most_recent   = true
}

locals {
  streaming_cert = coalesce(var.streaming_config.certificate_arn, data.aws_acm_certificate.wildcard_cert.arn)
}

resource "aws_cloudfront_origin_access_identity" "meadow_streaming_access_identity" {
  comment = var.stack_name
}

data "aws_iam_policy_document" "meadow_streaming_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.meadow_streaming.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.iam_arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.meadow_streaming.arn]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront_streaming_access" {
  bucket = aws_s3_bucket.meadow_streaming.id
  policy = data.aws_iam_policy_document.meadow_streaming_bucket_policy.json
}

resource "aws_cloudfront_function" "meadow_streaming_cors" {
  name    = "${var.stack_name}-cors-streaming-headers"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("${path.module}/js/cors_streaming_headers.js")
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = "Managed-CachingOptimized"
}

data "aws_cloudfront_origin_request_policy" "cors_s3_origin" {
  name = "Managed-CORS-S3Origin"
}

data "aws_cloudfront_response_headers_policy" "cors_with_preflight" {
  name = "Managed-CORS-With-Preflight"
}

resource "aws_cloudfront_distribution" "meadow_streaming" {
  enabled          = true
  is_ipv6_enabled  = true
  retain_on_delete = true
  aliases          = compact([var.streaming_config.alias, "${var.stack_name}-streaming.${var.dns_zone}"])
  price_class      = "PriceClass_100"

  origin {
    domain_name = aws_s3_bucket.meadow_streaming.bucket_domain_name
    origin_id   = "${var.stack_name}-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.meadow_streaming_access_identity.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "${var.stack_name}-origin"
    viewer_protocol_policy = "allow-all"

    cache_policy_id             = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id    = data.aws_cloudfront_origin_request_policy.cors_s3_origin.id
    response_headers_policy_id  = data.aws_cloudfront_response_headers_policy.cors_with_preflight.id

    lambda_function_association {
      event_type = "viewer-request"
      lambda_arn = aws_lambda_function.stream_authorizer.qualified_arn
    }

    lambda_function_association {
      event_type = "viewer-response"
      lambda_arn = aws_lambda_function.stream_authorizer.qualified_arn
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = local.streaming_cert
    ssl_support_method             = "sni-only"
  }
}

resource "aws_route53_record" "meadow_streaming_cloudfront" {
  zone_id = data.aws_route53_zone.app_zone.zone_id
  name    = "${var.stack_name}-streaming"
  type    = "A"

  alias {
    name                      = aws_cloudfront_distribution.meadow_streaming.domain_name
    zone_id                   = aws_cloudfront_distribution.meadow_streaming.hosted_zone_id
    evaluate_target_health    = false
  }
}

data "aws_route53_zone" "meadow_streaming_alias" {
  count = var.streaming_config.alias == "" ? 0 : 1
  name  = trimprefix(var.streaming_config.alias, regex("^.+?\\.", var.streaming_config.alias))
}

resource "aws_route53_record" "meadow_streaming_alias" {
  count   = var.streaming_config.alias == "" ? 0 : 1

  zone_id = data.aws_route53_zone.meadow_streaming_alias[count.index].zone_id
  name    = regex("^.+?\\.", var.streaming_config.alias)
  type    = "A"

  alias {
    name                      = aws_cloudfront_distribution.meadow_streaming.domain_name
    zone_id                   = aws_cloudfront_distribution.meadow_streaming.hosted_zone_id
    evaluate_target_health    = false
  }
}
