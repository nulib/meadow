variable "ssl_certificate_file" {
  type    = string
  default = "../../miscellany/devbox_cert/dev.rdc.wildcard.full.pem"
}

variable "ssl_key_file" {
  type    = string
  default = "../../miscellany/devbox_cert/dev.rdc.wildcard.key.pem"
}

variable "test_mode" {
  type    = bool
  default = false
}
