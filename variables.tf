variable "app_metadata" {
  description = <<EOF
Nullstone automatically injects metadata from the app module into this module through this variable.
This variable is a reserved variable for capabilities.
EOF

  type    = map(string)
  default = {}
}

variable "target_database" {
  type        = string
  default     = ""
  description = "The database applications connect to, which the restore replaces. Defaults to the connected database."
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

variable "backup_retention" {
  type    = number
  default = 1

  description = <<EOF
How many previous versions of the target database to keep.

Each is a full copy, so steady state is (1 + this) times the database size. Dropped at the *start*
of the next restore rather than the end of this one: a backup is only safe to discard once there is
a newer database to fall back to.
EOF
}
