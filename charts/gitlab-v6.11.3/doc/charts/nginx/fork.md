---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Our NGINX fork **(FREE SELF)**

Our [fork](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress) of the NGINX chart was pulled from [GitHub](https://github.com/kubernetes/ingress-nginx).

## Adjustments to the NGINX fork

The following adjustments were made to the NGINX fork:

- `tcp-configmap.yaml`: is optional depending on new `tcpExternalConfig` setting
- Ability to use a templated TCP ConfigMap name from another chart
  - `controller-configmap-tcp.yaml`: `.metadata.name` is a template `ingress-nginx.tcp-configmap`
  - `controller-deployment.yaml`: `.spec.template.spec.containers[0].args` uses `ingress-nginx.tcp-configmap` template for ConfigMap name
  - GitLab chart overrides `ingress-nginx.tcp-configmap` so that `gitlab/gitlab-org/charts/gitlab-shell` can configure its TCP service
- Ability to use a templated Ingress name based on the release name
- Replace `controller.service.loadBalancerIP` with `global.hosts.externalIP`
- Added support to add common labels through `common.labels` configuration option
- `controller-deployment.yaml`:
  - Add `podlabels` and `global.pod.labels` to `.spec.template.metadata.labels`
- `default-backend-deployment.yaml`:
  - Add `podlabels` and `global.pod.labels` to `.spec.template.metadata.labels`
- Disable NGINX's default nodeSelectors.
- Added support for PDB `maxUnavailable`.
- Remove NGINX's `isControllerTagValid` helper in `charts/nginx-ingress/templates/_helpers.tpl`
  - The check had not been updated since it was [implemented](https://github.com/kubernetes/ingress-nginx/pull/5252) in 2020.
  - As part of [#3383](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3383), we need to refer to a tag that will contain `ubi`,
    meaning that the `semverCompare` would not work as expected anyway.
- Added support for autoscaling/v2beta2 and autoscaling/v2 APIs in HPAs and
  extended HPA settings to support memory and custom metrics, as well as
  behavior configuration.
- Added conditional support for API version of PodDisruptionBudget.
- Add the following booleans to enable/disable GitLab Shell (SSH access) independently for the external and internal (if enabled with `controller.service.internal.enabled`) services:
  - `controller.service.enableShell`.
  - `controller.service.internal.enableShell`.
  (follows the exisiting chart pattern of `controller.service.enableHttp(s)`)
