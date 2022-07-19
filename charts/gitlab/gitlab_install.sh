#!/bin/sh

cd $(dirname $0)

helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm -n gitlab upgrade --install gitlab gitlab/gitlab \
   --timeout 600s \
   --set global.edition=ce \
   --global.hosts.domain=gitlab.local \
   --set certmanager-issuer.email=ENTET_YOUR_EMAIL@example.com \
   --set gitlab-runner.runners.privileged=true \
   --set global.hosts.https=false \
   --set global.shell.port=2222 \
   --set certmanager.installCRDs=false \
   --set kas.enables=false \
   --set nginx-ingress.enabled=false \
   --set global.ingress.class=nginx \
   --set global.certmanager.install=false \
   --set prometheus.install=false \
   --set gitlab-runner.install=false \
   --set global.hosts.externalIP=ENTER_YOUR_IP

