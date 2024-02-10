---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Using NGINX **(FREE SELF)**

We provide a complete NGINX deployment to be used as an Ingress Controller. Not all
Kubernetes providers natively support the NGINX [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls),
to ensure compatibility.

NOTE:
Our [fork](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress) of the NGINX chart was pulled from
[GitHub](https://github.com/kubernetes/ingress-nginx). See [Our NGINX fork](fork.md) for details on what was modified in our fork.

NOTE:
The version of the NGINX Ingress Helm chart bundled with the GitLab Helm charts
has been updated to support Kubernetes 1.22. As a result, the GitLab Helm
chart can not longer support Kubernetes versions prior to 1.19.

## Configuring NGINX

See [NGINX chart documentation](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/nginx-ingress/README.md#configuration)
for configuration details.

### Global settings

We share some common global settings among our charts. See the [Globals Documentation](../globals.md)
for common configuration options, such as GitLab and Registry hostnames.

## Configure hosts using the Global settings

The hostnames for the GitLab Server and the Registry Server can be configured using
our [Global settings](../globals.md) chart.

## Annotation value word blocklist

> Introduced in [GitLab Helm chart 6.6](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2713).

In situations where cluster operators need greater control over the generated
NGINX configuration, the NGINX Ingress allows for [configuration snippets](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)
which inserts "snippets" of raw NGINX configuration not addressed by the
standard annotations and ConfigMap entries.

The drawback of these configuration snippets is that it allows cluster
operators to deploy Ingress objects that include LUA scripting and similar
configurations that can compromise the security of your GitLab installation
and the cluster itself, including exposing serviceaccount tokens and secrets.

See [CVE-2021-25742](https://nvd.nist.gov/vuln/detail/CVE-2021-25742) and
[this upstream `ingress-nginx` issue](https://github.com/kubernetes/ingress-nginx/issues/7837)
for additional details.

In order to mitigate CVE-2021-25742 in Helm chart deployments of GitLab - we
set an [annotation-value-word-blocklist](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836)
using the [suggested settings from the `nginx-ingress` community](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotation-value-word-blocklist)

If you are making use of configuration snippets in your GitLab Ingress
configuration, or are using GitLab NGINX Ingress Controller with third-party
Ingress objects that use configuration snippets, you may experience `404`
errors when trying to visit your GitLab third-party domains and "invalid word"
errors in your `nginx-controller` logs. In that case, review and adjust your
`nginx-ingress.controller.config.annotation-value-word-blocklist` setting.

See also ["Invalid Word" errors in the `nginx-controller` logs and `404` errors in our chart troubleshooting docs](../../troubleshooting/index.md#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors).
