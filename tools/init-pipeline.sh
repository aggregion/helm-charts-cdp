#!/bin/bash

pip3 install yq

cat ../charts/pipeline/values.yaml | yq -y '{
  runner: {
    enabled: .runner.enabled,
    configs: {
      amqpUrl: .runner.configs.amqpUrl,
      cloudEventsListener: .runner.configs.cloudEventsListener,
      pipelines: {
        sconeCleanroom: {
          namespace: .runner.configs.pipelines.sconeCleanroom.namespace,
          pvcSize: .runner.configs.pipelines.sconeCleanroom.pvcSize,
          storageClassName: .runner.configs.pipelines.sconeCleanroom.storageClassName,
          podTemplate: {
            nodeSelector: .runner.configs.pipelines.sconeCleanroom.podTemplate.nodeSelector,
          },
        },
      },
      basePipelineOptions: {
        namespace: .runner.configs.basePipelineOptions.namespace,
        pvcSize: .runner.configs.basePipelineOptions.pvcSize,
        storageClassName: .runner.configs.basePipelineOptions.storageClassName,
      },
    },
  },
  watcher: {
    enabled: .watcher.enabled,
    image: {
      repository: .watcher.image.repository,
      tag: .watcher.image.tag,
    },
  },
}'
