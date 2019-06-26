output "db_address" {
  value = "${module.rds.this_db_instance_address}"
}

output "db_endpoint" {
  value = "${module.rds.this_db_instance_endpoint}"
}

output "db_password" {
  value = "${module.rds.this_db_instance_password}"
}
