variable "additional_hostnames" {
  type    = list(string)
  default = []
}

variable "canonical_hostname" {
  type    = string
  default = ""
}

variable "agentless_sso_key" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_size" {
  type    = number
  default = 5
}

variable "dcapi_stack_name" {
  type    = string
  default = "dc-api-v2"  
}

variable "certificate_name" {
  type    = string
  default = "*"
}

variable "digital_collections_bucket" {
  type = string
}

variable "digital_collections_url" {
  type = string
}

variable "embedding_model_id" {
  type = string
}

variable "embedding_dimensions" {
  type = number
}

variable "fixity_function" {
  type = string
}

variable "geonames_username" {
  type = string
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
  type    = map(any)
  default = {}
}

variable "upload_bucket" {
  type    = string
  default = ""
}

variable "nul_public_bucket" {
  type    = string
  default = ""
}

variable "pyramid_bucket" {
  type    = string
  default = ""
}

variable "preservation_check_bucket" {
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

variable "iiif_cloudfront_distribution_id" {
  type = string
}

variable "iiif_server_url" {
  type = string
}

variable "iiif_manifest_url" {
  type = string
}

variable "ec2_instance_users" {
  type = list(string)
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

variable "ffmpeg_layer_sha256" {
  type = string
}

variable "replication_region" {
  type    = string
  default = "us-west-2"
}

variable "shared_bucket" {
  type = string
}

variable "work_archiver_endpoint" {
  type = string
}

variable "dc_api_v2_base" {
  type = string
}

variable "streaming_config" {
  type    = map(string)
  default = {
    alias             = ""
    certificate_arn   = ""
  }
}

variable "preservation_check_schedule" {
  type    = string
  default = "0 2 * * *"
}

variable "trusted_referers" {
  type    = string
  default = ""
}
