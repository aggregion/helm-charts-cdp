---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Configure the GitLab chart with FIPS-compliant images

GitLab offers [FIPS-compliant](https://docs.gitlab.com/ee/development/fips_compliance.html)
versions of its images, allowing you to run GitLab on FIPS-enabled clusters.

## Sample values

We provide an example for GitLab chart values in
[`examples/fips/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/fips/values.yaml)
which can help you to build a FIPS-compatible GitLab deployment.

Note the comment under the `nginx-ingress.controller` key that provides the
relevant configuration to use a FIPS-compatible NGINX Ingress Controller image. This image is
maintained in our [NGINX Ingress Controller fork](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-ingress-nginx).
