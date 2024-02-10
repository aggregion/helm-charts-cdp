---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/product/ux/technical-writing/#assignments
---

# Deploy the GitLab Helm chart **(FREE SELF)**

Before running `helm install`, you need to make some decisions about how you will run GitLab.
Options can be specified using Helm's `--set option.name=value` command-line option.
This guide will cover required values and common options.
For a complete list of options, read [Installation command line options](command-line-options.md).

WARNING:
The default Helm chart configuration is **not intended for production**.
The default chart creates a proof of concept (PoC) implementation where all GitLab
services are deployed in the cluster. For production deployments, you must follow the
[Cloud Native Hybrid reference architecture](index.md#use-the-reference-architectures).

For a production deployment, you should have strong working knowledge of Kubernetes.
This method of deployment has different management, observability, and concepts than traditional deployments.

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

## Convert Community Edition to Enterprise Edition

If you [deployed the Community Edition](#deploy-the-community-edition) and you
want to convert to the Enterprise Edition, you need to redeploy GitLab without
specifying `--set global.edition=ce`. If you also specified
individual images (for example, `--set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce`),
you need to omit any occurrence of those images.

After the deployment, you can [activate your Enterprise Edition license](https://docs.gitlab.com/ee/user/admin_area/license.html).

## Install the product documentation

This is an optional step. See how to [self-host the product documentation](https://docs.gitlab.com/ee/administration/docs_self_host.html).
