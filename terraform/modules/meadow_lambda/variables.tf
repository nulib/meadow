variable "access_point_arn" {
  type    = string
  default = ""
}

variable "name" {
  type    = string
}

variable "description" {
  type    = string
}

variable "environment" {
  type    = map
  default = {}
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "memory_size" {
  type    = number
  default = 128
}

variable "timeout" {
  type    = number
  default = 3
}

variable "role" {
  type    = string
}

variable "stack_name" {
  type    = string
}

variable "tags" {
  type    = map
  default = {}
}

variable "subnet_ids" {
  type    = list
  default = []
}

variable "security_group_ids" {
  type    = list
  default = []
}