---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab chart prerequisites **(FREE SELF)**

Before you deploy GitLab in a Kubernetes cluster, install the following
prerequisites and decide on the options you'll use when you install.

## Prerequisites

### kubectl

Install `kubectl` by following [the Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/#kubectl).
The version you install must be [within one minor release](https://kubernetes.io/releases/version-skew-policy/#kubectl)
of the version running in your cluster.

### Helm

Install Helm v3.3.1 or later by following [the Helm documentation](https://helm.sh/docs/intro/install/).

### PostgreSQL

By default, the GitLab chart includes an in-cluster PostgreSQL deployment that
is provided by [`bitnami/PostgreSQL`](https://artifacthub.io/packages/helm/bitnami/postgresql).
This deployment is for trial purposes only and **not recommended for use in production**.

You should set up an
[external, production-ready PostgreSQL instance](../advanced/external-db/index.md).
PostgreSQL 13 is the recommended default version since GitLab chart 6.0.

As of GitLab chart 4.0.0, replication is available internally, but not enabled by default.
Such functionality has not been load tested by GitLab.

### Redis

By default, the GitLab chart includes an in-cluster Redis deployment that
is provided by [`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis).
This deployment is for trial purposes only and **not recommended for use in production**.

You should set up an
[external, production-ready Redis instance](../advanced/external-redis/index.md).
For all the available configuration settings, see the
[Redis globals documentation](../charts/globals.md#configure-redis-settings).

As of GitLab chart 4.0.0, replication is available internally, but
not enabled by default. Such functionality has not been load tested by GitLab.

## Decide on other options

You use the following options with `helm install` when you deploy GitLab.

### Secrets

You must create some secrets, like SSH keys. By default, these secrets
are generated automatically during the deployment, but if you want to
specify them, you can follow the [secrets documentation](secrets.md).

### Networking and DNS

By default, to expose services, GitLab uses name-based virtual servers that are
configured with `Ingress` objects. These objects are Kubernetes `Service` objects
of `type: LoadBalancer`.

You must specify a domain that contains records to resolve
`gitlab`, `registry`, and `minio` (if enabled) to the appropriate IP address for your chart.

For example, use the following with `helm install`:

```shell
--set global.hosts.domain=example.com
```

With custom domain support enabled, a `*.<pages domain>` sub-domain, which by default
is `<pages domain>`, becomes `pages.<global.hosts.domain>`.
The domain resolves to the external IP assigned to Pages
by `--set global.pages.externalHttp` or `--set global.pages.externalHttps`.

To use custom domains, GitLab Pages can use a CNAME record that points the custom
domain to a corresponding `<namespace>.<pages domain>` domain.

#### Dynamic IP addresses with `external-dns`

If you plan to use an automatic DNS registration service like
[`external-dns`](https://github.com/kubernetes-sigs/external-dns),
you don't need any additional DNS configuration for GitLab. However, you must deploy
`external-dns` to your cluster. The project page
[has a comprehensive guide](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster)
for each supported provider.

NOTE:
If you enable custom domain support for GitLab Pages, `external-dns` no
longer works for the Pages domain (`pages.<global.hosts.domain>` by default).
You must manually configure the DNS entry to point the domain to the
external IP address dedicated to Pages.

If you provision a [GKE cluster](cloud/gke.md) by using the provided script,
`external-dns` is automatically installed in your cluster.

#### Static IP addresses

If you plan to manually configure your DNS records, they should all point to a
static IP address. For example, if you choose `example.com` and you have a static IP address
of `10.10.10.10`, then `gitlab.example.com`, `registry.example.com` and
`minio.example.com` (if using MinIO) should all resolve to `10.10.10.10`.

If you are using GKE, read more on [creating the external IP and DNS entry](cloud/gke.md#creating-the-external-ip).
Consult your cloud or DNS provider's documentation for more help on this process.

For example, use the following with `helm install`:

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Compatibility with Istio protocol selection

Service port names follow the convention that is compatible with Istio's [explicit port selection](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection).
They look like `<protocol>-<suffix>`, for example `tls-gitaly` or `https-metrics`.

Note, that Gitaly uses gRPC, but does not have this suffix due to findings in [Issue #3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822).

### Persistence

By default the GitLab chart creates volume claims with the expectation that a
dynamic provisioner creates the underlying persistent volumes. If you would like
to customize the `storageClass` or manually create and assign volumes, review
the [storage documentation](storage.md).

NOTE:
After the initial deployment, making changes to your storage settings requires manually editing Kubernetes
objects. Therefore, it's best to plan ahead before deploying your production instance to avoid extra storage migration work.

### TLS certificates

You should be running GitLab with HTTPS, which requires TLS certificates. By default, the
GitLab chart installs and configures [`cert-manager`](https://github.com/jetstack/cert-manager)
to obtain free TLS certificates.

If you have your own wildcard certificate, or you already have `cert-manager` installed, or you
have some other way of obtaining TLS certificates, read more about [TLS options](tls.md).

For the default configuration, you must specify an email address to register your TLS
certificates. For example, use the following with `helm install`:

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus

We use the [upstream Prometheus chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration),
and do not override values from our own defaults other than a customized
`prometheus.yml` file to limit collection of metrics to the Kubernetes API
and the objects created by the GitLab chart. We do, however, by default disable
`alertmanager`, `nodeExporter`, and `pushgateway`.

The `prometheus.yml` file instructs Prometheus to collect metrics from
resources that have the `gitlab.com/prometheus_scrape` annotation. In addition,
the `gitlab.com/prometheus_path` and `gitlab.com/prometheus_port` annotations
may be used to configure how metrics are discovered. Each of these annotations
are comparable to the `prometheus.io/{scrape,path,port}` annotations.

If you are monitoring or want to monitor the GitLab application
with your installation of Prometheus, the original `prometheus.io/*`
annotations are still added to the appropriate Pods and Services. This allows
continuity of metrics collection for existing users and provides the ability
to use the default Prometheus configuration to capture both the GitLab
application metrics and other applications running in a Kubernetes cluster.

Refer to the [upstream Prometheus chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration) for the
exhaustive list of configuration options and ensure they are sub-keys to
`prometheus`, as we use this as requirement chart.

For instance, the requests for persistent storage can be controlled with:

```yaml
prometheus:
  alertmanager:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  pushgateway:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  server:
    persistentVolume:
      enabled: true
      size: 8Gi
```

#### Configure Prometheus to scrape TLS-enabled endpoints

Prometheus can be configured to scrape metrics from TLS-enabled endpoints if
the given exporter allows for TLS and the chart configuration exposes a TLS
configuration for the exporter's endpoint.

There are a few caveats when using TLS and [Kubernetes Service Discovery](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)
for the Prometheus [scrape configurations](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config):

- For the [pod](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)
  and [service endpoints](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)
  discovery roles, Prometheus uses the internal IP address of the Pod to set
  the address of the scrape target. To verify the TLS certificate, Prometheus
  must be configured with either the Common Name (CN) set in the certificate
  created for the metrics endpoint, or configured with a name included
  in the Subject Alternative Name (SAN) extension. The name does not have to
  resolve, and can be any arbitrary string that is a [valid DNS name](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1).
- If the certificate used for the exporter's endpoint is self-signed or
  otherwise not present in the Prometheus base image, the Prometheus pod
  must mount a certificate for the Certificate Authority (CA) that signed the
  certificate used for the exporter's endpoint. Prometheus uses a `ca-bundle` from
  Debian [in its base image](https://github.com/prometheus/busybox).
- Prometheus supports setting both of these items using a [tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config)
  which is applied to each of the scrape configurations. While Prometheus has
  a robust [relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)
  mechanism for setting Prometheus target labels based on Pod annotations and other
  discovered attributes, setting the `tls_config.server_name` and
  `tls_config.ca_file` is not possible using the `relabel_config`. See this
  [Prometheus project issue](https://github.com/prometheus/prometheus/issues/4827)
  for more details.

Given these caveats, the simplest configuration is to share a "name" and CA
across all certificates used for the exporter endpoints:

1. Choose a single arbitrary name to use for the `tls_config.server_name` (for example,
   `metrics.gitlab`).
1. Add that name to the SAN list for each certificate used to TLS encrypt
   the exporter endpoints.
1. Issue all certificates from the same CA:
   - Add the CA certificate as a cluster secret.
   - Mount that secret into the Prometheus server container using the
     [Prometheus chart's](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml)
     `extraSecretMounts:` configuration.
   - Set that as the `tls_config.ca_file` for the Prometheus `scrape_config`.

The [Prometheus TLS values example](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples/prometheus/values-tls.yaml)
provides an example for this shared configuration by:

1. Setting `tls_config.server_name` to `metrics.gitlab` for the pod/endpoint
   `scrape_config` roles.
1. Assuming that `metrics.gitlab` has been added to the SAN list for every
   certificate used for the exporter endpoint.
1. Assuming that the CA certificate has been added to a secret named
   `metrics.gitlab.tls-ca` with a secret key also named `metrics.gitlab.tls-ca`
   created in the same namespace that the Prometheus chart has been deployed
   to (for example, `kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`).
1. Mounting that `metrics.gitlab.tls-ca` secret to
   `/etc/ssl/certs/metrics.gitlab.tls-ca` using an `extraSecretMounts:` entry.
1. Setting `tls_config.ca_file` to `/etc/ssl/certs/metrics.gitlab.tls-ca`.

#### Exporter endpoints

Not all of the metrics endpoints included in the GitLab chart support TLS.
If the endpoint can be and is TLS-enabled they will also set the
`gitlab.com/prometheus_scheme: "https"` annotation, as well as the
`prometheus.io/scheme: "https"` annotation, either of which can be used with a
`relabel_config` to set the Prometheus `__scheme__` target label.
The [Prometheus TLS values example](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples/prometheus/values-tls.yaml)
includes a `relabel_config` that targets `__scheme__` using the
`gitlab.com/prometheus_scheme: "https"` annotation.

The following table lists the Deployments (or when using either or both of Gitaly and Praefect:
StatefulSets) and Service endpoints that have the
`gitlab.com/prometheus_scrape: true` annotation applied.

In the documentation links below, if the component mentions adding SAN entries,
make sure that you also add the SAN that you decided on using for the
Prometheus `tls_config.server_name`.

| Service | Metrics Port(default) | Supports TLS? | Notes/Docs/Issue |
| ---     | ---                   | ---           | ---              |
| [Gitaly](../charts/gitlab/gitaly/index.md)                   | 9236  | YES | Enabled using `global.gitaly.tls.enabled=true` <br>Default Secret: `RELEASE-gitaly-tls` <br>[Docs: Running Gitaly over TLS](../charts/gitlab/gitaly/index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/index.md) | 9168  | YES | Enabled using `gitlab.gitlab-exporter.tls.enabled=true` <br>Default Secret: `RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/index.md)       | 9235  | YES | Enabled using `gitlab.gitlab-pages.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-pages-metrics-tls` <br>[Docs: General settings](../charts/gitlab/gitlab-pages/index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/index.md)     | 9252  | NO  | [Issue - Add TLS Support for Metrics Endpoint](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/index.md)       | 9122  | NO  | The GitLab Shell metrics exporter is only enabled when using [`gitlab-sshd`](https://docs.gitlab.com/ee/administration/operations/gitlab_sshd.html). OpenSSH is recommended for environments that require TLS |
| [KAS](../charts/gitlab/kas/index.md)                         | 8151  | YES | Can be configured using `global.kas.customConfig.observability.listen.certificate_file` and `global.kas.customConfig.observability.listen.key_file` options |
| [Praefect](../charts/gitlab/praefect/index.md)               | 9236  | YES | Enabled using `global.praefect.tls.enabled=true` <br>Default Secret: `RELEASE-praefect-tls` <br>[Docs: Running Praefect over TLS](../charts/gitlab/praefect/index.md#running-praefect-over-tls) |
| [Registry](../charts/registry/index.md)                      | 5100  | YES | Enabled using `registry.debug.tls.enabled=true` <br>[Docs: Registry - Configuring TLS for the debug port](../charts/registry/index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/index.md)                 | 3807  | YES | Enabled using `gitlab.sidekiq.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-sidekiq-metrics-tls` <br>[Docs: Installation command line options](../charts/gitlab/sidekiq/index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/index.md)              | 8083  | YES | Enabled using `gitlab.webservice.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-webservice-metrics-tls` <br>[Docs: Installation command line options](../charts/gitlab/webservice/index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/index.md)                    | 10254 | NO  | Does not support TLS on metrics/healthcheck port |

For the webservice pod, the exposed port is the standalone webrick exporter in
the webservice container. The workhorse container port is not scraped. See the
[Webservice Metrics documentation](../charts/gitlab/webservice/index.md#metrics)
for additional details.

### Outgoing email

By default, outgoing email is disabled. To enable it, provide details for your SMTP server
using the `global.smtp` and `global.email` settings. You can find details for these settings in the
[command line options](command-line-options.md#outgoing-email-configuration).

If your SMTP server requires authentication, make sure to read the section on providing
your password in the [secrets documentation](secrets.md#smtp-password).
You can disable authentication settings with `--set global.smtp.authentication=""`.

If your Kubernetes cluster is on GKE, be aware that SMTP
[port 25 is blocked](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports).

### Incoming email

The configuration of incoming email is documented in the
[mailroom chart](../charts/gitlab/mailroom/index.md#incoming-email).

### Service Desk email

The configuration of incoming email is documented in the
[mailroom chart](../charts/gitlab/mailroom/index.md#service-desk-email).

### RBAC

The GitLab chart defaults to creating and using [RBAC](rbac.md). If your cluster does not
have RBAC enabled, you must disable these settings:

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## Next steps

[Set up your cloud provider and create your cluster](cloud/index.md).
