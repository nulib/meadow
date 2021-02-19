output "ec2_instance" {
  value = aws_route53_record.ec2_hostname.fqdn
}

output "endpoint" {
  value = "https://${aws_route53_record.app_hostname.fqdn}/"
}
