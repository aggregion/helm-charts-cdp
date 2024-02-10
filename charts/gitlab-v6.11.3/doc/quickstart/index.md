---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Test the GitLab chart on GKE or EKS

This guide serves as a concise but complete documentation about how to install the
GitLab chart with default values on Google Kubernetes Engine (GKE)
or Amazon Elastic Kubernetes Service (EKS).

By default, the GitLab chart includes an in-cluster PostgreSQL, Redis, and
MinIO deployment. Those are for trial purposes only and
**not recommended for use in production environments**.
If you wish to deploy these charts into production under sustained load, you
should follow the complete [installation guide](../installation/index.md).

## Prerequisites

To complete this guide, you must have the following:

- A domain you own, to which you can add a DNS record.
- A Kubernetes cluster.
- A working installation of `kubectl`.
- A working installation of Helm v3.

### Available domain

You must have access to an internet-accessible domain to which you can add
a DNS record. This can be a sub-domain such as `poc.domain.com`, but the
Let's Encrypt servers must be able to resolve the addresses in order to
issue certificates.

### Create a Kubernetes cluster

A cluster with a total of at least eight virtual CPUs and 30GB of RAM is recommended.

You can either refer to your cloud providers' instructions on how to create a Kubernetes cluster,
or use the GitLab-provided scripts to [automate the cluster creation](../installation/cloud/index.md).

### Install kubectl

To install kubectl, see the [Kubernetes installation documentation](https://kubernetes.io/docs/tasks/tools/).
The documentation covers most operating systems and the Google
Cloud SDK, which you may have installed during the previous step.

After you create the cluster, you must
[configure `kubectl`](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)
before you can interact with the cluster from the command line.

### Install Helm

For this guide, we use the latest release of Helm v3 (v3.3.1 or later).
To install Helm, see the [Helm installation documentation](https://helm.sh/docs/intro/install/).

## Add the GitLab Helm repository

Add the GitLab Helm repository to `helm`'s configuration:

```shell
helm repo add gitlab https://charts.gitlab.io/
```

## Install GitLab

Here's the beauty of what this chart is capable of. One command. Poof! All
of GitLab installed, and configured with SSL.

To configure the chart, you need:

- The domain or subdomain for GitLab to operate under.
- Your email address, so Let's Encrypt can issue a certificate.

To install the chart, run the install command with two
`--set` arguments:

```shell
helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com
```

This step can take several minutes in order for all resources
to be allocated, services to start, and access made available.

After it's completed, you can proceed to collect the IP address that has
been dynamically allocated for the installed NGINX Ingress.

## Retrieve the IP address

You can use `kubectl` to fetch the address that has been dynamically been
allocated by GKE to the NGINX Ingress you've just installed and configured as
a part of the GitLab chart:

```shell
kubectl get ingress -lrelease=gitlab
```

The output should look something like the following:

```plaintext
NAME               HOSTS                 ADDRESS         PORTS     AGE
gitlab-minio       minio.domain.tld      35.239.27.235   80, 443   118m
gitlab-registry    registry.domain.tld   35.239.27.235   80, 443   118m
gitlab-webservice  gitlab.domain.tld     35.239.27.235   80, 443   118m
```

You'll notice that there are three entries, all with the same IP address.
Take this IP address, and add it to your DNS for the domain
you have chosen to use. You can add multiple records of type `A`, but for
simplicity we recommend a single "wildcard" record:

- In Google Cloud DNS, create an `A` record with the name `*`. We also
  suggest setting the TTL to `1` minute instead of `5` minutes.
- On AWS EKS, the address will be a URL rather than an IP address.
  [Create a Route 53 alias record](https://aws.amazon.com/premiumsupport/knowledge-center/route-53-create-alias-records/)
  `*.domain.tld` pointing to this URL.

## Sign in to GitLab

You can access GitLab at `gitlab.domain.tld`. For example, if you set
`global.hosts.domain=my.domain.tld`, then you would visit `gitlab.my.domain.tld`.

To sign in, you must collect the password for the `root` user.
This is automatically generated at installation time and stored in a Kubernetes
Secret. Let's fetch that password from the secret and decode it:

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

You can now sign in to GitLab with username `root`, and the retrieved password.
You can change this password through the user preferences after logged in, we only
generate it so that we can secure the first login on your behalf.

## Troubleshooting

If you experience issues during this guide, here are a few likely items you should
be sure are working:

1. The `gitlab.my.domain.tld` resolves to the IP address of the Ingress you retrieved.
1. If you get a certificate warning, there has been a problem with Let's Encrypt,
   usually related to DNS, or the requirement to retry.

For further troubleshooting tips, see our [troubleshooting](../troubleshooting/index.md) guide.

### Helm install returns `roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden`

After running:

```shell
helm install gitlab gitlab/gitlab  \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=user@example.com
```

You might see an error similar to:

```shell
Error: failed pre-install: warning: Hook pre-install templates/shared-secrets-rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "some-user@some-domain.com" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

This means that the `kubectl` context that you are using to connect to the cluster
does not have the permissions needed to create [RBAC](../installation/rbac.md) resources.
