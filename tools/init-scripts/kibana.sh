#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/kibana/values.yaml | yq -y '{
  gatekeeper: {
    enabled: true,
    config: {
      clientId: .gatekeeper.config.clientId,
      clientSecret: .gatekeeper.config.clientSecret,
      discoveryUrl: .gatekeeper.config.discoveryUrl,
      encryptionKey: .gatekeeper.config.encryptionKey,
      redirectionUrl: .gatekeeper.config.redirectionUrl,
      verbose: .gatekeeper.config.verbose,
    }
  },
  elasticsearchHosts: .elasticsearchHosts,
  image: .image,
  imageTag: .imageTag,
  ingress: {
    enabled: .ingress.enabled,
    hosts: .ingress.hosts,
    tls: [{
      secretName: "chart-example-tls",
      hosts: [.ingress.hosts[0].host]
    }]
  },

}'
