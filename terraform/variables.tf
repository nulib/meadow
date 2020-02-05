variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "honeybadger_api_key" {
  type    = string
  default = ""
}

variable "ingest_bucket" {
  type    = string
  default = ""
}

variable "stack_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "dns_zone" {
  type = string
}

variable "tags" {
  type    = map
  default = {}
}

variable "upload_bucket" {
  type    = string
  default = ""
}

variable "pyramid_bucket" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type    = string
}

variable "ldap_base_dn" {
  type    = string
  default = "DC=library,DC=northwestern,DC=edu"
}

variable "ldap_bind_dn" {
  type    = string
}

variable "ldap_bind_password" {
  type    = string
}

variable "ldap_port" {
  type    = string
  default = 389
}

variable "ldap_server" {
  type    = string
}

variable "elasticsearch_url" {
  type    = string
}