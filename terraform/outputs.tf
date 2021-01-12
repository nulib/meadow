output "endpoint" {
  value = "https://${aws_route53_record.app_hostname.fqdn}/"
}
