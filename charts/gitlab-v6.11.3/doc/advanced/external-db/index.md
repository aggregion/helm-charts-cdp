---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the GitLab chart with an external database

For a production-ready GitLab chart deployment, use an external database.

Prerequisites:

- A deployment of PostgreSQL 12 or later. If you do not have one, consider
  a cloud provided solution like [AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/)
  or [GCP Cloud SQL](https://cloud.google.com/sql/). For a self-managed solution,
  consider [the Omnibus GitLab package](external-omnibus-psql.md).
- An empty database named `gitlabhq_production` by default.
- A user with full database access. See the
  [external database documentation](https://docs.gitlab.com/ee/administration/postgresql/external.html) for details.
- A [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/) with the password for the database user.
- The [`pg_trgm` and `btree_gist` extensions](https://docs.gitlab.com/ee/install/postgresql_extensions.html). If you don't provide an account with
  the Superuser flag to GitLab, ensure these extensions are loaded prior to
  proceeding with the database installation.

Networking prerequisites:

- Ensure that the database is reachable from the cluster. Be sure that your firewall policies allow traffic.
- If you plan to use PostgreSQL as a load balancing cluster and Kubernetes
  DNS for service discovery, when you install the `bitnami/postgresql` chart,
  use `--set slave.service.clusterIP=None`.
  This setting configures the PostgreSQL secondary service as a headless service to
  allow DNS `A` records to be created for each secondary instance.

  For an example of how to use Kubernetes DNS for service discovery,
  see [`examples/database/values-loadbalancing-discover.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml).

To configure the GitLab chart to use an external database:

1. Set the following parameters:

   - `postgresql.install`: Set to `false` to disable the embedded database.
   - `global.psql.host`: Set to the hostname of the external database, can be a domain or an IP address.
   - `global.psql.password.secret`: The name of the [secret that contains the database password for the `gitlab` user](../../installation/secrets.md#postgresql-password).
   - `global.psql.password.key`: Within the secret, the key that contains the password.

1. Optional. The following items can be further customized if you are not using the defaults:

   - `global.psql.port`: The port the database is available on. Defaults to `5432`.
   - `global.psql.database`: The name of the database.
   - `global.psql.username`: The user with access to the database.

1. Optional. If you use a mutual TLS connection to the database, set the following:

   - `global.psql.ssl.secret`: A secret that contains the client certificate, key, and certificate authority.
   - `global.psql.ssl.serverCA`: In the secret, the key that refers to the certificate authority (CA).
   - `global.psql.ssl.clientCertificate`: In the secret, the key that refers to the client certificate.
   - `global.psql.ssl.clientKey`: In the secret, the client.

1. When you deploy the GitLab chart, add the values by using the `--set` flag. For example:

   ```shell
   helm install gitlab gitlab/gitlab
     --set postgresql.install=false
     --set global.psql.host=psql.example
     --set global.psql.password.secret=gitlab-postgresql-password
     --set global.psql.password.key=postgres-password
   ```
