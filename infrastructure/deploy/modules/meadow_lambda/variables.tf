variable "name" {
  type = string
}

variable "description" {
  type = string
}

variable "environment" {
  type    = map(any)
  default = {}
}

variable "ephemeral_storage" {
  type    = number
  default = 512
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
  type = string
}

variable "stack_name" {
  type = string
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "layers" {
  type    = list(any)
  default = []
}
