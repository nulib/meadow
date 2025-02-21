resource "random_string" "db_password" {
  length  = "16"
  special = "false"
}

# provider "postgresql" {
#   host            = module.data_services.outputs.aurora.endpoint
#   port            = module.data_services.outputs.aurora.port
#   username        = module.data_services.outputs.aurora.admin_user
#   password        = module.data_services.outputs.aurora.admin_password
#   sslmode         = "require"
#   connect_timeout = 15
#   superuser       = false
# }

# resource "postgresql_role" "meadow" {
#   name        = "meadow"
#   password    = random_string.db_password.result
#   login       = true
# }

# resource "postgresql_database" "meadow" {
#   name        = "meadow"
#   owner       = postgresql_role.meadow.name
#   encoding    = "UTF8"
#   lc_collate  = "en_US.UTF-8"
#   template    = "template0"
# }

# resource "postgresql_extension" "uuid" {
#   name = "uuid-ossp"
# }