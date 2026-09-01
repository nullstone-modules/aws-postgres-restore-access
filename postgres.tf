data "ns_connection" "postgres" {
  name     = "postgres"
  contract = "datastore/aws/postgres:*"
}

locals {
  db_endpoint          = data.ns_connection.postgres.outputs.db_endpoint
  db_subdomain         = split(":", local.db_endpoint)[0]
  db_port              = split(":", local.db_endpoint)[1]
  db_security_group_id = data.ns_connection.postgres.outputs.db_security_group_id

  db_admin_func_name = data.ns_connection.postgres.outputs.db_admin_function_name
  db_admin_version   = try(data.ns_connection.postgres.outputs.db_admin_version, "0.6")
  postgres_ssl_mode  = try(data.ns_connection.postgres.outputs.postgres_ssl_mode, "prefer")

  // The managed superuser role differs by engine: rds_superuser on RDS and Aurora. Datastore
  // modules publish it as db_superuser_role.
  superuser_role = try(data.ns_connection.postgres.outputs.db_superuser_role, "rds_superuser")
}

locals {
  username = local.resource_name

  // Connects to `postgres` rather than the target: a session connected to a database cannot rename
  // it, and the swap renames two.
  admin_database = "postgres"

  postgres_url = join("", [
    "postgres://",
    urlencode(local.username), ":", urlencode(random_password.this.result),
    "@", local.db_endpoint, "/", urlencode(local.admin_database),
    "?sslmode=", urlencode(local.postgres_ssl_mode),
  ])
}
