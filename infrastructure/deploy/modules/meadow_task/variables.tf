variable "container_config" {
  type    = map(string)
}

variable "cpu" {
  type    = number
}

variable "db_pool_size" {
  type    = number
  default = 10
}

variable "db_queue_target" {
  type    = number
  default = 50
}

variable "db_queue_interval" {
  type    = number
  default = 1000
}

variable "livebook_shared_bucket" {
  type    = string
  default = ""
}

variable "meadow_processes" {
  type    = string
  default = "all"
}

variable "memory" {
  type    = number
}

variable "name" {
  type    = string
}

variable "role_arn" {
  type    = string
}

variable "stack_name" {
  type    = string
}

variable "tags" {
  type    = map(string)
}

