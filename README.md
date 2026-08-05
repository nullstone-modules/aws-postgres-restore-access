# aws-postgres-restore-access

Grants an app the Postgres access it needs to restore a scrubbed production snapshot over a
database.

This capability does **one** thing: it mints an instance-admin Postgres role through
`pg-db-admin` — which Terraform cannot reach directly, since the database sits inside a VPC — and
publishes the connection and the database names the restore needs.

Everything else is ordinary app configuration. See
[nullstone-io/pg-snapshot](https://github.com/nullstone-io/pg-snapshot) for the tool itself.

## Usage

Build an image with your migration tool in it:

```dockerfile
FROM nullstone/pg-snapshot:v1.0.0
COPY --from=migrations /app/bin/migrate /usr/local/bin/
COPY migrate.sh /app/migrate.sh
```

Deploy it as a job app running `restore` — the image's entrypoint is already `pgsnap` — then:

1. Attach **this capability**, connected to the Postgres datastore you are restoring over.
2. Attach **`aws-s3-access`** for the bucket the snapshots live in.
3. Set the rest as environment variables on the app:

```
S3_BUCKET_URL     where the snapshots live
S3_BUCKET_REGION
MIGRATE_COMMAND   e.g. /app/migrate.sh
SNAPSHOT          optional; pins a timestamp instead of taking the newest
NUM_WORKERS       optional
```

## What this capability provides

| | |
|---|---|
| `POSTGRES_URL` (secret) | the restore role, connected to the instance's `postgres` database |
| `TARGET_DATABASE` | the database the restore replaces |
| `OWNER_ROLE` | the role restored objects are owned by |
| `BACKUP_RETENTION` | how many previous versions of the target to keep |

The role holds membership in the managed superuser role (AWS's) and in the target's owner. It
needs `CREATEDB` to create the staging database *and* to rename databases at all, ownership of
the target to rename it, and the ability to terminate sessions and create non-trusted extensions.
One grant covers all of it.

Production gating is structural: attach this only to apps in environments that restore, and the
role exists nowhere else.

## What a restore does

1. Loads the snapshot into a fresh `restored_<id>` database, so the target is untouched until the
   very end.
2. Runs `MIGRATE_COMMAND` against it, reconciling schema drift — the snapshot carries production's
   migration-tracking table, so your own tool applies exactly the delta.
3. Swaps it into place with two catalog renames, keeping the previous database as
   `<target>_backup_<timestamp>`.

A failure anywhere before the swap discards the staging database and leaves the target exactly as
it was. A crash *during* the swap is recovered on the next run from the catalog itself.

## License

MIT
