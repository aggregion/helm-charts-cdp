#!/bin/sh -e

if [ -n "$KUBE_CONFIG" ]; then
  KUBE_CONFIG="--kubeconfig ${KUBE_CONFIG}"
fi

[ -z "$1" ] && echo 'Use: script NS USERNAME PASSWORD HOST' && exit 0
[ -z "$2" ] && echo 'ERROR: Empty username' && exit 0
[ -z "$3" ] && echo 'ERROR: Empty password' && exit 0
[ -z "$4" ] && echo 'ERROR: Empty host' && exit 0

kubectl \
        $KUBE_CONFIG -n "${1}" create secret docker-registry "${NAME:-aggregionregistry}" \
        --docker-username="${2}"                           \
        --docker-password="${3}"                           \
        --docker-server="${4}"                             \
        --docker-email="${5:-name@localhost.com}"
