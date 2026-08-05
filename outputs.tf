// This capability grants Postgres access and nothing else.
//
// The bucket the snapshots live in, the migration command, and pgsnap's runtime settings are
// configured on the app itself — an S3 access capability and ordinary environment variables. That
// keeps this module to the one thing it is uniquely able to do: mint a database role through
// pg-db-admin, which Terraform cannot reach directly.
output "env" {
  value = [
    {
      name  = "RESTORE_TARGET_DATABASE"
      value = local.target_database
    },
    {
      name  = "RESTORE_OWNER_ROLE"
      value = local.owner_role
    },
    {
      name  = "RESTORE_BACKUP_RETENTION"
      value = tostring(var.backup_retention)
    },
  ]
}

// The connection url carries an instance-admin password, so it goes in the app's secret store
// rather than its environment
output "secrets" {
  value = [
    {
      name  = "POSTGRES_URL"
      value = local.postgres_url
    },
  ]
}
