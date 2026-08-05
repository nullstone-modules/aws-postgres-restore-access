output "env" {
  value = [
    {
      name  = "RESTORE_OWNER_ROLE"
      value = local.owner_role
    },
    {
      name  = "POSTGRES_HOST"
      value = local.db_subdomain
    },
    {
      name  = "POSTGRES_USER"
      value = local.username
    },
    {
      name  = "POSTGRES_DB"
      value = local.admin_database
    }
  ]
}

output "secrets" {
  value = [
    {
      name  = "POSTGRES_PASSWORD"
      value = random_password.this.result
    },
    {
      name  = "POSTGRES_URL"
      value = local.postgres_url
    }
  ]
}
