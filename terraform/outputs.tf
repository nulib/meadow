output "endpoint" {
  value = "${aws_route53_record.app_hostname.fqdn}"
}
