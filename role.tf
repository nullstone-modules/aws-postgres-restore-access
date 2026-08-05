// Terraform cannot reach a database inside a VPC, so every statement here is routed through the
// pg-db-admin Lambda the datastore module already deploys. It holds the master credentials; this
// capability never sees them.
//
// The restore role is an instance-level admin. It needs CREATEDB (to create the staging database
// *and* to rename databases at all), ownership of the target, the ability to terminate other
// sessions, and the ability to create non-trusted extensions. Membership in rds_superuser covers
// all of it in one grant.
//
// Production gating is structural rather than a flag: attach this capability only to apps in
// environments that restore, and the role does not exist anywhere else.
resource "aws_lambda_invocation" "role" {
  function_name   = local.db_admin_func_name
  lifecycle_scope = "CRUD"

  input = jsonencode({
    type = "roles"
    data = {
      name     = local.username
      password = random_password.this.result
      attributes = {
        createDb    = true
        replication = true
      }
      useExisting = true
    }
  })
}

resource "aws_lambda_invocation" "superuser_role_member" {
  function_name   = local.db_admin_func_name
  lifecycle_scope = "CRUD"

  input = jsonencode({
    type = "role_members"
    data = {
      target      = local.superuser_role
      member      = local.username
      useExisting = true
    }
  })

  depends_on = [aws_lambda_invocation.role]
}

// The restored objects must end up owned by the role that owned them before the swap, or the
// applications lose access to their own tables. pg_restore --role creates them owned correctly
// from the start, which is why there is no REASSIGN OWNED pass anywhere in the restore.
resource "aws_lambda_invocation" "owner_role_member" {
  function_name   = local.db_admin_func_name
  lifecycle_scope = "CRUD"

  input = jsonencode({
    type = "role_members"
    data = {
      target      = local.owner_role
      member      = local.username
      useExisting = true
    }
  })

  depends_on = [aws_lambda_invocation.role]
}
