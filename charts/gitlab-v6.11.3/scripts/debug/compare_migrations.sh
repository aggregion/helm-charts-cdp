#!/bin/bash

# This script relies on:
# - kubectl already having the correct context
# - mikefarah/yq being available as `yq`
# - skopeo available

# Input:
#
# 1. Release Name
# 2. Namespace (optional)
#
# Output:
#
# RELEASE_NAME:
#   migrations:
#     image: registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee
#     digest: sha256:8dc004e513066b6e13b2037513cb5fa754cd8c0685d7905f5698702e9ffa8a9e
#     created: 2023-01-30T21:15:23.890247432Z # fetched from registry via skopeo
#   toolbox:
#     image: registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee
#     digest: sha256:8dc004e513066b6e13b2037513cb5fa754cd8c0685d7905f5698702e9ffa8a9e
#     created: 2023-01-30T21:15:23.890247432Z # fetched from registry via skopeo

if [ -z "$1" ]; then
  echo "ERROR: release name required"
  exit 1 
fi

RELEASE=$1
NAMESPACE=$2

find_imageID() {
  app=$1

  namespace=
  if [ -n "$NAMESPACE" ]; then
    namespace="-n ${NAMESPACE}"
  fi

  # shellcheck disable=SC2086
  pod=$(kubectl ${namespace} get pod -l"release=${RELEASE},app=${app}" -ojsonpath='{.items[0].metadata.name}' 2>/dev/null)
  if [ -z "$pod" ]; then
    echo "ERROR: Unable to locate Pod for ${app}, check that Context / Release / Namespace are correct"
    return 1
  fi

  # shellcheck disable=SC2086
  imageID=$(kubectl ${namespace} get pod "${pod}" -o yaml | app="${app}" yq '.status.containerStatuses[] | select(.name == env(app)) | .imageID')

  image=${imageID#docker-pullable://}
  image=${image%@*}
  digest=${imageID##*@}
  echo -e "  ${app}:\n    image: ${image}\n    digest: ${digest}"

  created=$(skopeo inspect "docker://${image}@${digest}" | yq '.Created')
  echo "    created: ${created}"
}

echo "${RELEASE}:"
find_imageID migrations
find_imageID toolbox