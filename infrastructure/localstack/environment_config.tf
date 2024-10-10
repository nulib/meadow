locals {
  project       = "meadow"
  port_offset   = 0 # terraform.workspace == "test" ? 2 : 1

  computed_secrets = {
    db   = {
      host        = "localhost"
      port        = 5432 + local.port_offset
      user        = "docker"
      password    = "d0ck3r"
    }

    index = {
      index_endpoint    = "http://localhost:${9200 + local.port_offset}"
      kibana_endpoint   = "http://localhost:${5601 + local.port_offset}"
    }
    ldap = {
      host       = "localhost"
      base       = "DC=library,DC=northwestern,DC=edu"
      port       = 389 + local.port_offset
      user_dn    = "cn=Administrator,cn=Users,dc=library,dc=northwestern,dc=edu"
      password   = "d0ck3rAdm1n!"
      ssl        = "false"
    }
  }

  config_secrets = merge(var.config_secrets, local.computed_secrets)
}

resource "aws_secretsmanager_secret" "config_secrets" {
  name    = "config/meadow"
  description = "Meadow configuration secrets"
}

resource "aws_secretsmanager_secret" "ssl_certificate" {
  name = "config/wildcard_ssl"
  description = "Wildcard SSL certificate and private key"
}

resource "aws_secretsmanager_secret_version" "config_secrets" {
  secret_id = aws_secretsmanager_secret.config_secrets.id
  secret_string = jsonencode(local.config_secrets)
}

resource "aws_secretsmanager_secret_version" "ssl_certificate" {
  secret_id       = aws_secretsmanager_secret.ssl_certificate.id
  secret_string   = jsonencode({
    certificate = file(var.ssl_certificate_file)
    key         = file(var.ssl_key_file)
  })
}
