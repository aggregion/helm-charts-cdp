#/bin/bash

# This script tests upgrades to the `kubectl` image, which contains
# `kubectl` and `yq`. It is important to test that Secrets created
# by Shared Secrets are not overwritten if they already exist.
# This script specifically tests the Rails Secret, which is a critical
# piece of data that must not change once created.
#
# For added context, previous updates to yq have changed syntax which led
# to shared-secrets overriding existing Secrets. We document the need to
# back up Secrets, especially the Rails Secret, but we should do our due
# diligence to ensure that data integrity as well.
#
# Test steps:
#   1. Creating a KinD cluster
#   2. Deploying the Helm Chart from `master` branch
#   3. Getting a copy of the Rails Secret
#   4. Upgrading chart from the feature branch
#   5. Getting a copy of the Rails Secret again
#   6. Confirming no difference in the collected Secrets
#   7. Upgrading the chart from the feature branch again
#   8. Getting a copy of the Rails Secret again
#   9. Confirming no difference in the collected secrets
#
# Prerequisites:
# 1. Ensure the following are installed:
#  - `kind`
#  - `kubectl`
#  - `helm`
#  - `diff`
#  - `base64`
# 2. Clone the project and check out the feature branch locally.
# 3. Ensure your shell is pointed to the root directory of the project.
# 4. Run `./scripts/test_kubectl_image_update.sh`.

# Fail script on error, and print out commands
set -ex

install_chart () {
  helm upgrade --install --create-namespace \
    gitlab . \
    -n gitlab \
    -f examples/kind/values-base.yaml \
    -f examples/kind/values-ssl.yaml
}

get_secret () {
  kubectl -n gitlab \
    get secret gitlab-rails-secret \
    -o jsonpath="{.data.secrets\.yml}" \
    | base64 --decode > $1
}

# Create KinD cluster if needed
kind get clusters | grep yq-test || \
  kind create cluster --config examples/kind/kind-ssl.yaml --name=yq-test

# Install chart from `master`
git checkout master
install_chart

# Save copy of the secret from initial install
get_secret secret-fresh-install.yaml

# Upgrade chart to this branch
git switch -
install_chart

# Get content of secret again
get_secret secret-upgrade-1.yaml

# Confirm no difference between secrets
diff secret-fresh-install.yaml secret-upgrade-1.yaml

# Upgrade chart (to trigger another shared-secrets job)
install_chart

# Get content of secret again
get_secret secret-upgrade-2.yaml

# Confirm no difference between secrets
diff secret-upgrade-1.yaml secret-upgrade-2.yaml

printf "Test passed. You can now delete the cluster:\n  kind delete cluster --name=yq-test\n"
