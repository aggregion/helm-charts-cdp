---
stage: Enablement
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#designated-technical-writers
---

# Deployment Guide **(FREE SELF)**

Before running `helm install`, you need to make some decisions about how you will run GitLab.
Options can be specified using Helm's `--set option.name=value` command line option.
This guide will cover required values and common options.
For a complete list of options, read [Installation command line options](command-line-options.md).

## Selecting configuration options

In each section collect the options that will be combined to use with `helm install`.

### Secrets

There are some secrets that need to be created (e.g. SSH keys). By default they will be generated automatically, but if you want to specify them, you can follow the [secrets guide](secrets.md).

### Networking and DNS

By default, the chart relies on Kubernetes `Service` objects of `type: LoadBalancer`
to expose GitLab services using name-based virtual servers configured with`Ingress`
objects. You'll need to specify a domain which will contain records to resolve
`gitlab`, `registry`, and `minio` (if enabled) to the appropriate IP for your chart.

*Include these options in your Helm install command:*

```shell
--set global.hosts.domain=example.com
```

As an example:

With custom domain support enabled, a `*.<pages domain>`
sub-domain, which by default is `<pages domain>`, becomes `pages.<global.hosts.domain>`, and will need to resolve to the external IP assigned to Pages (by `--set global.pages.externalHttp` or `--set global.pages.externalHttps`). To use custom domains, GitLab Pages can use a CNAME record pointing the custom domain to a corresponding `<namespace>.<pages domain>` domain.

#### Dynamic IPs with external-dns

If you plan to use an automatic DNS registration service like [external-dns](https://github.com/kubernetes-sigs/external-dns),
you won't need any additional configuration for GitLab, but you will need to deploy it to your cluster. If external-dns is your choice, the project page [has a comprehensive guide](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster) for each supported provider.

NOTE:
If you enable custom domain support for GitLab Pages, external-dns will no
longer work for the Pages domain (`pages.<global.hosts.domain>` by default), and
you will have to manually configure DNS entry to point the domain to the
external IP dedicated to Pages.

If you provisioned a GKE cluster using the scripts in this repository, [external-dns](https://github.com/kubernetes-sigs/external-dns)
is already installed in your cluster.

#### Static IP

If you plan to manually configure your DNS records they should all point to a
static IP. For example if you choose `example.com` and you have a static IP
of `10.10.10.10`, then `gitlab.example.com`, `registry.example.com` and
`minio.example.com` (if using MinIO) should all resolve to `10.10.10.10`.

If you are using GKE, read more on [creating the external IP and DNS entry](cloud/gke.md#creating-the-external-ip).
Consult your Cloud and/or DNS provider's documentation for more help on this process.

*Include these options in your Helm install command:*

```shell
--set global.hosts.externalIP=10.10.10.10
```

### Persistence

By default the chart will create Volume Claims with the expectation that a dynamic provisioner will create the underlying Persistent Volumes. If you would like to customize the storageClass or manually create and assign volumes, please review the [storage documentation](storage.md).

> **Important**: After initial installation, making changes to your storage settings requires manually editing Kubernetes
> objects, so it's best to plan ahead before installing your production instance of GitLab to avoid extra storage migration work.

### TLS certificates

You should be running GitLab using https which requires TLS certificates. By default the
chart will install and configure [cert-manager](https://github.com/jetstack/cert-manager)
to obtain free TLS certificates.
If you have your own wildcard certificate, you already have cert-manager installed, or you
have some other way of obtaining TLS certificates, read about more [TLS options](tls.md).

For the default configuration, you must specify an email address to register your TLS
certificates.

*Include these options in your Helm install command:*

```shell
--set certmanager-issuer.email=me@example.com
```

### PostgreSQL

It's recommended to set up an
[external production-ready PostgreSQL instance](../advanced/external-db/index.md).

As of GitLab Chart 4.0.0, replication is available internally, but _not enabled by default_. Such functionality has not been load tested by GitLab.

NOTE:
By default, the GitLab Chart includes an in-cluster PostgreSQL deployment that
is provided by [`bitnami/PostgreSQL`](https://artifacthub.io/packages/helm/bitnami/postgresql).
This is for trial purposes only and **not recommended for use in production**.

NOTE:
As of GitLab Chart 6.0, PostgreSQL 13 is the recommended default version.

### Redis

It's recommended to set up an
[external production-ready Redis instance](../advanced/external-redis/index.md).
For all the available configuration settings, see the
[Redis globals documentation](../charts/globals.md#configure-redis-settings).

As of GitLab Chart 4.0.0, replication is available internally, but
_not enabled by default_. Such functionality has not been load tested by GitLab.

NOTE:
By default, the GitLab Chart includes an in-cluster Redis deployment that
is provided by [`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis).
This is for trial purposes only and **not recommended for use in production**.

### MinIO

It's recommended to set up an
[external production-ready object storage](../advanced/external-object-storage/index.md)

NOTE:
By default, the GitLab chart provides an in-cluster MinIO deployment to provide an object storage API.
A singleton, non-resilient Deployment is provided by our [MinIO fork](../charts/minio/index.md).
This is for trial purposes only and **not recommended for use in production**.

### Prometheus

We use the [upstream Prometheus chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration),
and do not override values from our own defaults other than a customized
`prometheus.yml` file to limit collection of metrics to the Kubernetes API
and the objects created by the GitLab chart. We do, however, default disable
`alertmanager`, `nodeExporter`, and `pushgateway`.

The `prometheus.yml` file instructs Prometheus to collect metrics from
resources that have the `gitlab.com/prometheus_scrape` annotation. In addition,
the `gitlab.com/prometheus_path` and `gitlab.com/prometheus_port` annotations
may be used to configure how metrics are discovered. Each of these annotations
are comparable to the `prometheus.io/{scrape,path,port}` annotations.

For users that may be monitoring or want to monitor the GitLab application
with their installation of Prometheus, the original `prometheus.io/*`
annotations are still added to the appropriate Pods and Services. This allows
continuity of metrics collection for existing users and provides the ability
to use the default Prometheus configuration to capture both the GitLab
application metrics and other applications running in a Kubernetes cluster.

Refer to the [Prometheus chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration) for the
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

#### Configuring Prometheus to scrape TLS-enabled endpoints

Prometheus can be configured to scrape metrics from TLS-enabled endpoints if
the given exporter allows for TLS and the chart configuration exposes a TLS
configuration for the exporter's endpoint.

There a few caveats when using TLS and [Kubernetes Service Discovery](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)
for the Prometheus [scrape configurations](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config):

- With the [pod](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)
and [service endpoints](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)
discovery roles - Prometheus uses the internal IP address of the Pod to set
the address of the scrape target. To verify the SSL certificate, Prometheus
needs to be configured with either the Common Name (CN) set in the certificate
created for the metrics endpoint, or configured with a name included
in the Subject Alternative Name (SAN) extension. The name does not have to
resolve, and can be any arbitrary string that is a [valid DNS name](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1).
- If the certificate used for the exporter's endpoint is self-signed or
otherwise not present in the Prometheus base image - the Prometheus pod
needs to mount a certificate for the Certificate Authority (CA) that signed the
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

Not all of the metrics endpoints included in the Chart support TLS.
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
please make sure that you also add the SAN that you decided on using for the
Prometheus `tls_config.server_name`.

| Service | Metrics Port(default) | Supports TLS? | Notes/Docs/Issue |
| ---     | ---                   | ---           | ---              |
| [Gitaly](../charts/gitlab/gitaly/index.md)                   | 9236  | YES | Enabled using `global.gitaly.tls.enabled=true` <br>Default Secret: `RELEASE-gitaly-tls` <br>[Docs: Running Gitaly over TLS](../charts/gitlab/gitaly/index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/index.md) | 9168  | YES | Enabled using `gitlab.gitlab-exporter.tls.enabled=true` <br>Default Secret: `RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/index.md)       | 9235  | YES | Enabled using `gitlab.gitlab-pages.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-pages-metrics-tls` <br>[Docs: General settings](../charts/gitlab/gitlab-pages/index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/index.md)     | 9252  | NO  | [Issue - Add TLS Support for Metrics Endpoint](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/index.md)       | 9122  | NO  | The GitLab Shell metrics exporter is only enabled when using [`gitlab-sshd`](https://docs.gitlab.com/ee/administration/operations/fast_ssh_key_lookup.html#use-gitlab-sshd-instead-of-openssh). OpenSSH is recommended for environments that require TLS |
| [KAS](../charts/gitlab/kas/index.md)                         | 8151  | NO  | [Issue - Add TLS Support for Metrics Endpoint](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/issues/288) |
| [Praefect](../charts/gitlab/praefect/index.md)               | 9236  | YES | Enabled using `global.praefect.tls.enabled=true` <br>Default Secret: `RELEASE-praefect-tls` <br>[Docs: Running Praefect over TLS](../charts/gitlab/praefect/index.md#running-praefect-over-tls) |
| [Registry](../charts/registry/index.md)                      | 5100  | NO  | [Issue - Add support of TLS on `http.debug`](https://gitlab.com/gitlab-org/container-registry/-/issues/729) |
| [Sidekiq](../charts/gitlab/sidekiq/index.md)                 | 3807  | YES | Enabled using `gitlab.sidekiq.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-sidekiq-metrics-tls` <br>[Docs: Installation command line options](../charts/gitlab/sidekiq/index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/index.md)              | 8083  | YES | Enabled using `gitlab.webservice.metrics.tls.enabled=true` <br>Default Secret: `RELEASE-webservice-metrics-tls` <br>[Docs: Installation command line options](../charts/gitlab/webservice/index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/index.md)                    | 10254 | NO  | Does not support TLS on metrics/healthcheck port |

For the webservice pod, the exposed port is the standalone webrick exporter in
the webservice container. The workhorse container port is not scraped. See the
[Webservice Metrics documentation](../charts/gitlab/webservice/index.md#metrics)
for additional details.

### Outgoing email

By default outgoing email is disabled. To enable it, provide details for your SMTP server
using the `global.smtp` and `global.email` settings. You can find details for these settings in the
[command line options](command-line-options.md#outgoing-email-configuration).

If your SMTP server requires authentication make sure to read the section on providing
your password in the [secrets documentation](secrets.md#smtp-password).
You can disable authentication settings with `--set global.smtp.authentication=""`.

If your Kubernetes cluster is on GKE, be aware that SMTP [port 25
is blocked](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports).

### Incoming email

The configuration of incoming email is now documented in the [mailroom chart](../charts/gitlab/mailroom/index.md#incoming-email).

### Service Desk email

The configuration of incoming email is now documented in the [mailroom chart](../charts/gitlab/mailroom/index.md#service-desk-email).

### RBAC

This chart defaults to creating and using RBAC. If your cluster does not have RBAC enabled, you will need to disable these settings:

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

### CPU and RAM Resource Requirements

The resource requests, and number of replicas for the GitLab components (not PostgreSQL, Redis, or MinIO) in this Chart
are set by default to be adequate for a small production deployment. This is intended to fit in a cluster with at least 8vCPU
and 30gb of RAM. If you are trying to deploy a non-production instance, you can reduce the defaults in order to fit into
a smaller cluster.

The [minimal GKE example values file](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml) provides an example of tuning the resources
to fit within a 3vCPU 12gb cluster.

The [minimal minikube example values file](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-minikube-minimum.yaml) provides an example of tuning the
resources to fit within a 2vCPU, 4gb minikube instance.

## Deploy using Helm

Once you have all of your configuration options collected, we can get any dependencies and
run Helm. In this example, we've named our Helm release `gitlab`.

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=me@example.com \
  --set postgresql.image.tag=13.6.0
```

Note the following:

- All Helm commands are specified using Helm v3 syntax.
- Helm v3 requires that the release name be specified as a
  positional argument on the command line unless the `--generate-name` option is used.
- Helm v3 requires one to specify a duration with a unit appended to the value
  (e.g. `120s` = `2m` and `210s` = `3m30s`). The `--timeout` option is handled as the
  number of seconds _without_ the unit specification.
- The use of the `--timeout` option is deceptive in that there are multiple components that are
  deployed during an Helm install or upgrade in which the `--timeout` is applied. The `--timeout`
  value is applied to the installation of each component individually and not applied for the
  installation of all the components. So intending to abort the Helm install after 3 minutes by
  using `--timeout=3m` may result in the install completing after 5 minutes because none of the
  installed components took longer than 3 minutes to install.

You can also use `--version <installation version>` option if you would like to install a specific version of GitLab.

For mappings between chart versions and GitLab versions, read [GitLab version mappings](version_mappings.md).

Instructions for installing a development branch rather than a tagged release can be found in the [developer deploy documentation](../development/deploy.md).

## Monitoring the Deployment

This will output the list of resources installed once the deployment finishes which may take 5-10 minutes.

The status of the deployment can be checked by running `helm status gitlab` which can also be done while
the deployment is taking place if you run the command in another terminal.

## Initial login

You can access the GitLab instance by visiting the domain specified during
installation. The default domain would be `gitlab.example.com`, unless the
[global host settings](../charts/globals.md#configure-host-settings) were changed.
If you manually created the secret for initial root password, you
can use that to sign in as `root` user. If not, GitLab would've automatically
created a random password for `root` user. This can be extracted by the
following command (replace `<name>` by name of the release - which is `gitlab`
if you used the command above).

```shell
kubectl get secret <name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

## Deploy the Community Edition

By default, the Helm charts use the Enterprise Edition of GitLab. The Enterprise Edition is a free, open core version of GitLab with the option of upgrading to a paid tier to unlock additional features. If desired, you can instead use the Community Edition which is licensed under the MIT Expat license. Learn more about the [difference between the two](https://about.gitlab.com/install/ce-or-ee/).

*To deploy the Community Edition, include this option in your Helm install command:*

```shell
--set global.edition=ce
```

## Install the product documentation

This is an optional step. See how to [self-host the product documentation](https://docs.gitlab.com/ee/administration/docs_self_host.html).
