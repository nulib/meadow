variable "aws_region" {
  type    = "string"
  default = "us-east-1"
}
variable "availability_zones" {
  type    = "list"
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "stack_name" {
  type = "string"
}

variable "dns_zone" {
  type = "string"
}
