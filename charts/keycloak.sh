#!/bin/sh
helm upgrade --install --create-namespace \
  -n betatravel \
  -f keycloal_values.yaml \
  betaatlas \
  ./keycloak