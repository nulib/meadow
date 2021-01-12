variable "container_config" {
  type    = map(string)
}

variable "cpu" {
  type    = number
}

variable "file_system_id" {
  type    = string
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

