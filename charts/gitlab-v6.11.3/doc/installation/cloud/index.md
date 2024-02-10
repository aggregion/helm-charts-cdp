---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Cloud provider setup for the GitLab chart **(FREE SELF)**

Before you deploy the GitLab chart, you must configure resources for
the cloud provider you choose.

The GitLab chart is intended to fit in a cluster with at least 8 vCPU
and 30 GB of RAM. If you are trying to deploy a non-production instance,
you can reduce the defaults to fit into a smaller cluster.

A Kubernetes cluster, running version 1.19 through 1.25, is required because of certain
Kubernetes features. 1.25 is supported as of Chart 6.6 (GitLab 15.6).

NOTE:
Disabling the in-chart NGINX Ingress Controller (`nginx-ingress.enabled=false`),
allows the use of Kubernetes 1.16 or later.

- For cluster topology recommendations for an environment, see the
  [reference architectures](https://docs.gitlab.com/ee/administration/reference_architectures/#available-reference-architectures).
- For an example of tuning the resources to fit in a 3 vCPU 12 GB cluster, see the
  [minimal GKE example values file](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml).

Create and connect to a Kubernetes cluster in your environment:

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
