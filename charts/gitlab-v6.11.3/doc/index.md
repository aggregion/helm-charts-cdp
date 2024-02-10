---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# GitLab Helm chart **(FREE SELF)**

To install a cloud-native version of GitLab, use the GitLab Helm chart.
This chart contains all the required components to get started and can scale to large deployments.

For OpenShift-based installations, use [GitLab Operator](https://docs.gitlab.com/operator/),
otherwise you'll have to update the [security context constraints](https://docs.gitlab.com/operator/security_context_constraints.html)
yourself.

WARNING:
The default Helm chart configuration is **not intended for production**.
The default chart creates a proof of concept (PoC) implementation where all GitLab
services are deployed in the cluster. For production deployments, you must follow the
[Cloud Native Hybrid reference architecture](installation/index.md#use-the-reference-architectures).

For a production deployment, you should have strong working knowledge of Kubernetes.
This method of deployment has different management, observability, and concepts than traditional deployments.

The GitLab Helm chart is made up of multiple [subcharts](charts/gitlab/index.md),
each of which can be installed separately.

## Learn more

- [Test the GitLab chart on GKE or EKS](quickstart/index.md)
- [Migrate from Omnibus to the GitLab chart](installation/migration/index.md)
- [Prepare to deploy](installation/index.md)
- [Deploy](installation/deployment.md)
- [View deployment options](installation/command-line-options.md)
- [Configure globals](charts/globals.md)
- [View the subcharts](charts/gitlab/index.md)
- [View advanced configuration options](advanced/index.md)
- [View architectural decisions](architecture/index.md)
- Contribute to development by viewing the [developer documentation](development/index.md) and
  [contribution guidelines](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/CONTRIBUTING.md)
- Create an [issue](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)
- Create a [merge request](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests)
- View [troubleshooting](troubleshooting/index.md) information
