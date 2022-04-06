variable "description" {
  type = string
}

variable "function_name" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "memory_size" {
  type    = number
  default = 256
}

variable "runtime" {
  type    = string
  default = "nodejs14.x"
}

variable "source_dir" {
  type = string
}

variable "timeout" {
  type    = number
  default = 3
}
