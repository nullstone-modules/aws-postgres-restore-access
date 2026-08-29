variable "app_metadata" {
  description = <<EOF
Nullstone automatically injects metadata from the app module into this module through this variable.
This variable is a reserved variable for capabilities.
EOF

  type    = map(string)
  default = {}
}

variable "owner_role" {
  type    = string
  default = ""

  description = <<EOF
Role that owns the restored objects. Defaults to the target database name, matching how pg-db-admin
names database owners.

pg_restore --role creates objects owned correctly as they go, so the swapped-in database has the
same ownership topology as the one it replaced, and applications keep access to their own tables.

The following identifiers are supported for interpolation:
  {{ NULLSTONE_STACK }}
  {{ NULLSTONE_BLOCK }}
  {{ NULLSTONE_APP }}
  {{ NULLSTONE_ENV }}
EOF
}

// We are using ns_env_variables to interpolate owner_role.
// NULLSTONE_APP is a legacy alias for NULLSTONE_BLOCK.
data "ns_env_variables" "names" {
  input_env_variables = tomap({
    NULLSTONE_STACK = local.stack_name
    NULLSTONE_BLOCK = local.block_name
    NULLSTONE_APP   = local.block_name
    NULLSTONE_ENV   = local.env_name
    OWNER_ROLE      = coalesce(var.owner_role, local.block_name)
  })
  input_secrets = tomap({})
}

locals {
  owner_role = data.ns_env_variables.names.env_variables["OWNER_ROLE"]
}
