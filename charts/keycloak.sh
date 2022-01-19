#!/bin/sh
helm upgrade --install --create-namespace \
  -n keycloak \
  -f keycloak_values.yaml \
  betaatlas \
  ./keycloak