#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/keycloak19/values.yaml | yq -y '{
  keycloak: {
    enabled: true,
  },
}'
