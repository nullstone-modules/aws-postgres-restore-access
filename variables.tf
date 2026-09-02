variable "app_metadata" {
  description = <<EOF
Nullstone automatically injects metadata from the app module into this module through this variable.
This variable is a reserved variable for capabilities.
EOF

  type    = map(string)
  default = {}
}

locals {
  security_group_id = var.app_metadata["security_group_id"]
}

variable "target_database" {
  type    = string
  default = ""

  description = <<EOF
Database the restore replaces. Defaults to the app name, matching how postgres-access names the
database it creates.

The following identifiers are supported for interpolation:
  {{ NULLSTONE_STACK }}
  {{ NULLSTONE_BLOCK }}
  {{ NULLSTONE_APP }}
  {{ NULLSTONE_ENV }}
EOF
}

// We are using ns_env_variables to interpolate target_database.
// NULLSTONE_APP is a legacy alias for NULLSTONE_BLOCK.
data "ns_env_variables" "names" {
  input_env_variables = tomap({
    NULLSTONE_STACK = local.stack_name
    NULLSTONE_BLOCK = local.block_name
    NULLSTONE_APP   = local.block_name
    NULLSTONE_ENV   = local.env_name
    TARGET_DATABASE = coalesce(var.target_database, local.block_name)
  })
  input_secrets = tomap({})
}

locals {
  target_database = data.ns_env_variables.names.env_variables["TARGET_DATABASE"]

  // The owner role is the database name, always. That is how pg-db-admin names database owners
  // and how postgres-access grants every application membership in it, so it is the one role
  // restored objects can belong to and still be reachable by the apps through inheritance alone.
  //
  // This is deliberately not a variable. Naming any other role here restores every table owned
  // by a role the applications are not members of, and nothing in the restore can grant its way
  // out of that: the apps lose access to the whole schema on the first swap.
  //
  // pg_restore --role creates objects owned by this role as they go, so the swapped-in database
  // has the same ownership topology as the one it replaced.
  owner_role = local.target_database
}
