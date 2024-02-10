---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Using the GitLab `kas` chart **(FREE SELF)**

The `kas` sub-chart provides a configurable deployment of the
[GitLab agent server (KAS)](https://docs.gitlab.com/ee/administration/clusters/kas.html).
The agent server is a component you install together with GitLab. It is required to
manage the [GitLab agent for Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent).

This chart depends on access to the GitLab API and the Gitaly Servers.
When you enable this chart, an Ingress is deployed.

To consume minimal resources, the `kas` container uses a distroless image.
The deployed services are exposed by an Ingress, which uses
[WebSocket proxying](https://nginx.org/en/docs/http/websocket.html) for communication.
This proxy allows long-lived connections with the external component,
[`agentk`](https://docs.gitlab.com/ee/user/clusters/agent/install/index.html).
`agentk` is the Kubernetes cluster-side agent counterpart.

The route to access the service depends on your [Ingress configuration](#specify-an-ingress).

For more information, see the
[GitLab agent for Kubernetes architecture](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

## Disable the agent server

The GitLab agent server (`kas`) is enabled by default.
To disable it on your GitLab instance, set the Helm property `global.kas.enabled` to `false`.

For example:

```shell
helm upgrade --install kas --set global.kas.enabled=false
```

### Specify an Ingress

When you use the chart's Ingress with the default configuration,
the service for the agent server is reachable on a subdomain.
For example, for `global.hosts.domain: example.com`, the agent server
is reachable at `kas.example.com`.

The [KAS Ingress](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/ingress.yaml)
can use a different domain than the `global.hosts.domain`.

Set `global.hosts.kas.name`, for example:

```shell
global.hosts.kas.name: kas.my-other-domain.com
```

This example uses `kas.my-other-domain.com` as the host for the KAS Ingress alone.
The rest of the services (including GitLab, Registry, MinIO, etc.) use the domain
specified in `global.hosts.domain`.

### Installation command line options

You can pass these parameters to the `helm install` command by using the `--set` flags.

| Parameter                                  | Default                                               | Description                                                                                                                                                                                                                                                |
|--------------------------------------------|-------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `annotations`                              | `{}`                                                  | Pod annotations.                                                                                                                                                                                                                                           |
| `common.labels`                            | `{}`                                                  | Supplemental labels that are applied to all objects created by this chart.                                                                                                                                                                                 |
| `extraContainers`                          |                                                       | List of extra containers to include.                                                                                                                                                                                                                       |
| `extraEnv`                                       |                                                   | List of extra environment variables to expose                                                                                                                                  |
| `extraEnvFrom`                                   |                                                   | List of extra environment variables from other data sources to expose                                                                                                          |
| `image.repository`                         | `registry.gitlab.com/gitlab-org/build/cng/gitlab-kas` | Image repository.                                                                                                                                                                                                                                          |
| `image.tag`                                | `v13.7.0`                                             | Image tag.                                                                                                                                                                                                                                                 |
| `hpa.behavior`                             | `{scaleDown: {stabilizationWindowSeconds: 300 }}`     | Behavior contains the specifications for up- and downscaling behavior (requires `autoscaling/v2beta2` or higher).                                                                                                                                          |
| `hpa.customMetrics`                        | `[]`                                                  | Custom metrics contains the specifications for which to use to calculate the desired replica count (overrides the default use of Average CPU Utilization configured in `targetAverageUtilization`).                                                        |
| `hpa.cpu.targetType`                       | `AverageValue`                                        | Set the autoscaling CPU target type, must be either `Utilization` or `AverageValue`.                                                                                                                                                                       |
| `hpa.cpu.targetAverageValue`               | `100m`                                                | Set the autoscaling CPU target value.                                                                                                                                                                                                                      |
| `hpa.cpu.targetAverageUtilization`         |                                                       | Set the autoscaling CPU target utilization.                                                                                                                                                                                                                |
| `hpa.memory.targetType`                    |                                                       | Set the autoscaling memory target type, must be either `Utilization` or `AverageValue`.                                                                                                                                                                    |
| `hpa.memory.targetAverageValue`            |                                                       | Set the autoscaling memory target value.                                                                                                                                                                                                                   |
| `hpa.memory.targetAverageUtilization`      |                                                       | Set the autoscaling memory target utilization.                                                                                                                                                                                                             |
| `hpa.targetAverageValue`                   |                                                       | **DEPRECATED** Set the autoscaling CPU target value                                                                                                                                                                                                        |
| `ingress.enabled`                          | `true` if `global.kas.enabled=true`                   | You can use `kas.ingress.enabled` to explicitly turn it on or off. If not set, you can optionally use `global.ingress.enabled` for the same purpose.                                                                                                       |
| `ingress.apiVersion`                       |                                                       | Value to use in the `apiVersion` field.                                                                                                                                                                                                                    |
| `ingress.annotations`                      | `{}`                                                  | Ingress annotations.                                                                                                                                                                                                                                       |
| `ingress.tls`                              | `{}`                                                  | Ingress TLS configuration.                                                                                                                                                                                                                                 |
| `ingress.agentPath`                        | `/`                                                   | Ingress path for the agent API endpoint.                                                                                                                                                                                                                   |
| `ingress.k8sApiPath`                       | `/k8s-proxy`                                          | Ingress path for Kubernetes API endpoint.                                                                                                                                                                                                                  |
| `metrics.enabled`                          | `true`                                                | If a metrics endpoint should be made available for scraping.                                                                                                                                                                                               |
| `metrics.port`                             | `8151`                                                | **DEPRECATED: use `observability.port`**. Metrics endpoint port.                                                                                                                                                                                           |
| `metrics.path`                             | `/metrics`                                            | Metrics endpoint path.                                                                                                                                                                                                                                     |
| `metrics.serviceMonitor.enabled`           | `false`                                               | If a ServiceMonitor should be created to enable Prometheus Operator to manage the metrics scraping. Enabling removes the `prometheus.io` scrape annotations.                                                                                               |
| `metrics.serviceMonitor.additionalLabels`  | `{}`                                                  | Additional labels to add to the ServiceMonitor.                                                                                                                                                                                                            |
| `metrics.serviceMonitor.endpointConfig`    | `{}`                                                  | Additional endpoint configuration for the ServiceMonitor.                                                                                                                                                                                                  |
| `maxReplicas`                              | `10`                                                  | HPA `maxReplicas`.                                                                                                                                                                                                                                         |
| `maxUnavailable`                           | `1`                                                   | HPA `maxUnavailable`.                                                                                                                                                                                                                                      |
| `minReplicas`                              | `2`                                                   | HPA `maxReplicas`.                                                                                                                                                                                                                                         |
| `nodeSelector`                             |                                                       | Define a [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) for the `Pod`s of this `Deployment`, if present.                                                                                            |
| `observability.port`                       | `8151`                                                | Observability endpoint port. Used for metrics and probe endpoints.                                                                                                                                                                                         |
| `observability.livenessProbe.path`         | `/liveness`                                           | URI for the liveness probe endpoint. This value has to match the `observability.liveness_probe.url_path` value from the KAS service configuration.                                                                                                         |
| `observability.readinessProbe.path`        | `/readiness`                                          | URI for the readiness probe endpoint. This value has to match the `observability.readiness_probe.url_path` value from the KAS service configuration.                                                                                                       |
| `serviceAccount.annotations`               | `{}`                                                  | Service account annotations.                                                                                                                                                                                                                               |
| `podLabels`                                | `{}`                                                  | Supplemental Pod labels. Not used for selectors.                                                                                                                                                                                                           |
| `serviceLabels`                            | `{}`                                                  | Supplemental service labels.                                                                                                                                                                                                                               |
| `common.labels`                            |                                                       | Supplemental labels that are applied to all objects created by this chart.                                                                                                                                                                                 |
| `redis.enabled`                            | `true`                                                | Allows opting-out of using Redis for KAS features. Warnings: Redis will become a hard dependency soon, so this key is already deprecated.                                                                                                                  |
| `resources.requests.cpu`                   | `75m`                                                 | GitLab Exporter minimum CPU.                                                                                                                                                                                                                               |
| `resources.requests.memory`                | `100M`                                                | GitLab Exporter minimum memory.                                                                                                                                                                                                                            |
| `service.externalPort`                     | `8150`                                                | External port (for `agentk` connections).                                                                                                                                                                                                                  |
| `service.internalPort`                     | `8150`                                                | Internal port (for `agentk` connections).                                                                                                                                                                                                                  |
| `service.apiInternalPort`                  | `8153`                                                | Internal port for the internal API (for GitLab backend).                                                                                                                                                                                                   |
| `service.loadBalancerIP`                   | `nil`                                                 | A custom load balancer IP when `service.type` is `LoadBalancer`.                                                                                                                                                                                           |
| `service.loadBalancerSourceRanges`         | `nil`                                                 | A list of custom load balancer source ranges when `service.type` is `LoadBalancer`.                                                                                                                                                                        |
| `service.kubernetesApiPort`                | `8154`                                                | External port to expose proxied Kubernetes API on.                                                                                                                                                                                                         |
| `service.privateApiPort`                   | `8155`                                                | Internal port to expose `kas`' private API on (for `kas` -> `kas` communication).                                                                                                                                                                          |
| `privateApi.secret`                        | Autogenerated                                         | The name of the secret to use for authenticating with the database.                                                                                                                                                                                        |
| `privateApi.key`                           | Autogenerated                                         | The name of the key in `privateApi.secret` to use.                                                                                                                                                                                                         |
| `privateApi.tls.enabled`                   | `false`                                               | **DEPRECATED: use `global.kas.tls.enabled`**. Enable `kas` pods to communicate with each other using TLS.                                                                                                                                                  |
| `privateApi.tls.secretName`                | `nil`                                                 | **DEPRECATED: use `global.kas.tls.secretName`**. Name of the [Kubernetes TLS secret](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) which contains the certificate and its associated key. Required if `privateApi.tls` is `true`. |
| `global.kas.service.apiExternalPort`       | `8153`                                                | External port for the internal API (for GitLab backend).                                                                                                                                                                                                   |
| `service.type`                             | `ClusterIP`                                           | Service type.                                                                                                                                                                                                                                              |
| `tolerations`                              | `[]`                                                  | Toleration labels for pod assignment.                                                                                                                                                                                                                      |
| `customConfig`                             | `{}`                                                  | When given, merges the default `kas` configuration with these values giving precedence to those defined here.                                                                                                                                              |
| `deployment.minReadySeconds`               | `0`                                                   | Minimum number of seconds that must pass before a `kas` pod is considered ready.                                                                                                                                                                           |
| `deployment.strategy`                      | `{}`                                                  | Allows one to configure the update strategy utilized by the deployment.                                                                                                                                                                                    |
| `deployment.terminationGracePeriodSeconds` | `300`                                                 | How much time in seconds a Pod is allowed to spend shutting down after receiving SIGTERM.                                                                                                                                                                  |
| `priorityClassName`                        |                                                       | [Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assigned to pods.                                                                                                                                       |

## Enable TLS communication

> - The `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` attributes were
    [deprecated](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3843) in GitLab 15.8, and will be
    removed in GitLab 17.0. Enable TLS via the [global KAS attribute](../../globals.md#tls-settings-1)
    instead.

Enable TLS communication between your `kas` pods and other GitLab chart components,
through the [global KAS attribute](../../globals.md#tls-settings-1).

## Enable TLS communication through the `gitlab.kas.privateApi` attributes (deprecated)

WARNING:
The `gitlab.kas.privateApi.tls.enabled` and `gitlab.kas.privateApi.tls.secretName` attributes were
[deprecated](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3843) in GitLab 15.8, and will be
removed in GitLab 17.0. Enable TLS via the [global KAS attribute](../../globals.md#tls-settings-1) instead.

Prerequisites:

- Use [GitLab 15.5.1 or later](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101571#note_1146419137).
  You can set your GitLab version with `global.gitlabVersion: <version>`. If you need to force an image update
  after an initial deployment, also set `global.image.pullPolicy: Always`.

1. Create the certificate authority and certificates that your `kas` pods will trust.
1. Configure your chart to use the trusted certificates.
1. Optional. Configure [Redis for TLS](../../globals.md#specify-secure-redis-scheme-ssl).

To configure `kas` to use the certificates you created, set the following values.

| Value | Description |
|-------|-------------|
| `global.certificates.customCAs` | Shares your CA with your GitLab components. |
| `global.appConfig.gitlab_kas.internalUrl` | Enables `grpcs` communication between the GitLab Webservice and `kas`. |
| `gitlab.kas.privateApi.tls.enabled` | Mounts the certificates volume and enables TLS communication between `kas` pods. |
| `gitlab.kas.privateApi.tls.secretName` | Specifies which Kubernetes TLS secret stores your certificates. |
| `gitlab.kas.customConfig` | Configures `kas` to expose its ports by using `grpcs`. |
| `gitlab.kas.ingress` | Configures `kas` Ingress to verify the proxied SSL certificate. |

For example, you could use this `values.yaml` file to deploy your chart:

   ```yaml
   .internal-ca: &internal-ca gitlab-internal-tls-ca # The secret name you used to share your TLS CA.
   .internal-tls: &internal-tls gitlab-internal-tls # The secret name you used to share your TLS certificate.

   global:
     certificates:
       customCAs:
       - secret: *internal-ca
     hosts:
       domain: gitlab.example.com # Your gitlab domain
     appConfig:
       gitlab_kas:
         internalUrl: "grpcs://RELEASE-kas.NAMESPACE.svc:8153" # Replace RELEASE and NAMESPACE with your chart's release and namespace

   gitlab:
     kas:
       privateApi:
         tls:
           enabled: true
           secretName: *internal-tls
       customConfig:
         api:
           listen:
             certificate_file: /etc/kas/tls.crt
             key_file: /etc/kas/tls.key
         agent:
           listen:
             certificate_file: /etc/kas/tls.crt
             key_file: /etc/kas/tls.key
           kubernetes_api:
             listen:
               certificate_file: /etc/kas/tls.crt
               key_file: /etc/kas/tls.key
       ingress:
         annotations:
           nginx.ingress.kubernetes.io/backend-protocol: https
           nginx.ingress.kubernetes.io/proxy-ssl-name: RELEASE-kas.NAMESPACE.svc # Replace RELEASE and NAMESPACE with your chart's release and namespace
           nginx.ingress.kubernetes.io/proxy-ssl-secret: NAMESPACE/CA-SECRET-NAME # Replace NAMESPACE and CA-SECRET-NAME with your chart's namespace and CA secret name. The same you used for &internal-ca.
           nginx.ingress.kubernetes.io/proxy-ssl-verify: on
   ```

## Test the `kas` chart

To install the chart:

1. Create your own Kubernetes cluster.
1. Check out the merge request's working branch.
1. Install (or upgrade) GitLab with `kas` enabled by default from your local chart branch:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600s \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com
   ```

1. Use the GDK to run the process to configure and use the
   [GitLab agent for Kubernetes](https://docs.gitlab.com/ee/user/clusters/agent/):
   (You can also follow the steps to configure and use the agent manually.)

   1. From your GDK GitLab repository, move into the QA folder: `cd qa`.
   1. Run the following command to run the QA test:

      ```shell
      GITLAB_USERNAME=$ROOT_USER
      GITLAB_PASSWORD=$ROOT_PASSWORD
      GITLAB_ADMIN_USERNAME=$ROOT_USER
      GITLAB_ADMIN_PASSWORD=$ROOT_PASSWORD
      bundle exec bin/qa Test::Instance::All https://your.gitlab.domain/ -- --tag orchestrated --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
      ```

      You can also customize the `agentk` version to install with an environment variable: `GITLAB_AGENTK_VERSION=v13.7.1`
