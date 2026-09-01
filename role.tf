// Terraform cannot reach a database inside a VPC, so every statement here is routed through the
// pg-db-admin Lambda the datastore module already deploys. It holds the master credentials; this
// capability never sees them.
//
// The restore role is an instance-level admin. It needs CREATEDB (to create the staging database
// *and* to rename databases at all), ownership of the target, the ability to terminate other
// sessions, and the ability to create non-trusted extensions. Membership in rds_superuser covers
// all of it in one grant.
//
// REPLICATION is deliberately absent. Setting the attribute requires a true superuser, which the
// RDS master user behind pg-db-admin is not, so asking for it fails the apply outright. The cost is
// that pg-snapshot cannot rebind logical replication slots across the swap: it warns before the swap
// and logs an error after, and the restore still succeeds. Slots left orphaned on a backup database
// block that backup from being dropped later, so grant rds_replication separately if the target ever
// gains a logical consumer.
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
        createDb = true
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

// GRANT fails outright if the owner role does not exist yet, which happens whenever this capability
// is applied before the postgres-access capability that owns the database. Creating it here mirrors
// the `database_owner` invocation in postgres-access, and the two are idempotent no-ops on each
// other regardless of which runs first.
//
// No password and no attributes, deliberately. pg-db-admin skips the password update when the field
// is blank, so this never disturbs an existing role's credentials, and its attribute handling only
// ever adds attributes -- granting one here would leave it on the role permanently.
resource "aws_lambda_invocation" "owner_role" {
  function_name   = local.db_admin_func_name
  lifecycle_scope = "CRUD"

  input = jsonencode({
    type = "roles"
    data = {
      name        = local.owner_role
      useExisting = true
    }
  })
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

  depends_on = [
    aws_lambda_invocation.role,
    aws_lambda_invocation.owner_role
  ]
}
