variable "additional_hostnames" {
  type    = list(string)
  default = []
}

variable "agentless_sso_key" {
  type    = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "certificate_name" {
  type    = string
  default = "*"
}

variable "digital_collections_url" {
  type    = string
}

variable "geonames_username" {
  type    = string
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

variable "migration_binary_bucket" {
  type    = string
  default = ""
}

variable "migration_manifest_bucket" {
  type    = string
  default = ""
}

variable "vpc_id" {
  type = string
}

variable "ldap_base_dn" {
  type    = string
  default = "DC=library,DC=northwestern,DC=edu"
}

variable "ldap_bind_dn" {
  type = string
}

variable "ldap_bind_password" {
  type = string
}

variable "ldap_port" {
  type    = string
  default = 389
}

variable "ldap_server" {
  type = string
}

variable "elasticsearch_url" {
  type = string
}

variable "iiif_server_url" {
  type = string
}

variable "iiif_manifest_url" {
  type = string
}

variable "ec2_instance_users" {
  type    = list(string)
}

variable "ezid_password" {
  type = string
}

variable "ezid_shoulder" {
  type = string
}

variable "ezid_target_base_url" {
  type = string
}

variable "ezid_user" {
  type = string
}
