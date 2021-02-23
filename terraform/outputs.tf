output "ec2_instance" {
  value = aws_route53_record.ec2_hostname.fqdn
}

output "endpoint" {
  value = "https://${aws_route53_record.app_hostname.fqdn}/"
}

output "upload_user_key_id" {
  value = {
    aws_access_key_id = aws_iam_access_key.upload_user_access_key.id,
    aws_secret_access_key = aws_iam_access_key.upload_user_access_key.secret
  }
}
