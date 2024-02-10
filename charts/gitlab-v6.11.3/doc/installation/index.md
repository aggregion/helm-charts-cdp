---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Installing GitLab by using Helm **(FREE SELF)**

Install GitLab on Kubernetes by using the cloud native GitLab Helm chart.

Assuming you already have the [prerequisites](tools.md) installed and configured,
you can [deploy GitLab](deployment.md) with the `helm` command.

WARNING:
The default Helm chart configuration is **not intended for production**.
The default chart creates a proof of concept (PoC) implementation where all GitLab
services are deployed in the cluster. For production deployments, you must follow the
[Cloud Native Hybrid reference architecture](#use-the-reference-architectures).

For a production deployment, you should have strong working knowledge of Kubernetes.
This method of deployment has different management, observability, and concepts than traditional deployments.

In a production deployment:

- The stateful components, like PostgreSQL or Gitaly (a Git repository storage dataplane),
  must run outside the cluster on PaaS or compute instances. This configuration is required
  to scale and reliably service the variety of workloads found in production GitLab environments.
- You should use Cloud PaaS for PostgreSQL, Redis, and object storage for all non-Git repository storage.

If Kubernetes is not required for your GitLab instance, see the
[reference architectures](https://docs.gitlab.com/ee/administration/reference_architectures/)
for simpler alternatives.

## Configure the Helm chart to use external stateful data

You can configure the GitLab Helm chart to point to external stateful storage
for items like PostgreSQL, Redis, all non-Git repository storage, as well as Git repository storage (Gitaly).

The following Infrastructure as Code (IaC) options use this approach.

For production-grade implementation, the appropriate chart parameters should be used to
point to prebuilt, externalized state stores that align with the chosen
[reference architecture](https://docs.gitlab.com/ee/administration/reference_architectures/).

### Use the reference architectures

The reference architecture for deploying GitLab instances to Kubernetes is called [Cloud Native Hybrid](https://docs.gitlab.com/ee/administration/reference_architectures/#cloud-native-hybrid) specifically because not all GitLab services can run in the cluster for production-grade implementations. All stateful GitLab components must be deployed outside the Kubernetes cluster.

Available Cloud Native Hybrid reference architectures sizes
are listed at [Reference architectures](https://docs.gitlab.com/ee/administration/reference_architectures/#cloud-native-hybrid) page.
For example, here is the [Cloud Native Hybrid reference architecture](https://docs.gitlab.com/ee/administration/reference_architectures/3k_users.html#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) for the 3,000 user count.

### Use Infrastructure as Code (IaC) and builder resources

GitLab develops Infrastructure as Code that is capable of configuring the combination of Helm charts and supplemental cloud infrastructure:

- [GitLab Environment Toolkit IaC](https://gitlab.com/gitlab-org/quality/gitlab-environment-toolkit).
- [AWS Quick Start on EKS IaC](https://docs.gitlab.com/ee/install/aws/gitlab_hybrid_on_aws.html):
  This tooling is under development. For GA status, follow
  [this issue](https://gitlab.com/gitlab-com/alliances/aws/public-tracker/-/issues/11).
- [Implementation pattern: Provision GitLab cloud native hybrid on AWS EKS](https://docs.gitlab.com/ee/install/aws/gitlab_hybrid_on_aws.html):
  This resource provides a Bill of Materials tested with the GitLab Performance Toolkit,
  and uses the AWS Cost Calculator for budgeting.
