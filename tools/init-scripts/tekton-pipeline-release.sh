#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/tekton/helm/pipeline-release/values.yaml | yq -y '{
  cloudevent: {
    enabled: .cloudevent.enabled,
    webhookUrl: .cloudevent.webhookUrl,
  },
  webhookServiceAccount: {
    create: .webhookServiceAccount.create,
  },
  pruner: {
    enabled: .pruner.enabled,
    schedule: .pruner.schedule,
    backoffLimit: .pruner.backoffLimit,
  },
}'
