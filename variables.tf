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
EOF
}
