#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/keycloak19/values.yaml | yq -y '{
  keycloak: {
    enabled: true,
  },
  image: {
    repository: "keycloak",
    tag: "dcp-master-dc64cbef-19"
  },
  auth: {
    adminUser: "admin"
  },
  extraEnvVars: [
    {
      name: "KEYCLOAK_PRODUCTION",
      value: "true"
    },
    {
      name: "KEYCLOAK_LOG_OUTPUT",
      value: "json"
    },
    {
      name: "KEYCLOAK_EXTRA_ARGS",
      value: "--spi-login-protocol-openid-connect-legacy-logout-redirect-uri=true --log-level=INFO,org.keycloak.events:debug,freemarker.runtime:fatal,org.keycloak.events.jpa.JpaEventStoreProvider:info"
    }
  ],
  service: {
    type: "NodePort"
  },
  proxy: "edge",
  ingress: {
    enabled: true,
    hostname: "keycloak.dcp.com",
    annotations: {
      "kubernetes.io/ingress.class": "nginx",
      "cert-manager.io/cluster-issuer": "letsencrypt-prod"
    },
    tls: true
  }
}'
