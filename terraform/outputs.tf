output "endpoint" {
  value = "http://${aws_route53_record.app_hostname.fqdn}/"
}
