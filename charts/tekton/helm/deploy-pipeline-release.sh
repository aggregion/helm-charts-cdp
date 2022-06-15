#!/bin/bash

helm upgrade --install -n tekton-pipelines tekton-pipelines ./pipeline-release

##### Example
# helm upgrade --install -n pipelines --kubeconfig ~/Downloads/keeley.yaml \
#    --set runner.image.tag=f6370102 \
#    --set watcher.image.tag=f6370102 \
#    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.infra.svc.cluster.local:5672 \
#    pipelines ./pipeline
#############
