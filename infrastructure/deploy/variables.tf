variable "additional_hostnames" {
  type    = list(string)
  default = []
}

variable "canonical_hostname" {
  type    = string
  default = ""
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "availability_zones" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "db_pool_size" {
  type    = number
  default = 100
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

variable "ec2_instance_users" {
  type = list(string)
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

variable "livebook_shared_bucket" {
  type    = string
  default = ""
}

variable "transcription_bucket" {
  type    = string
  default = ""
}
