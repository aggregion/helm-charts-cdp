#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/aggregion-externals/values.yaml | yq -y '{
  clickhouse: {
    enabled: .clickhouse.enabled,
    storageSize: .clickhouse.storageSize,
    storageClass: .clickhouse.storageClass,
    image: {
      repository: .clickhouse.image.repository,
      tag: .clickhouse.image.tag,
    },
  },
  mongo: {
    enabled: .mongo.enabled,
    storageSize: .mongo.storageSize,
    storageClass: .mongo.storageClass,
    image: {
      repository: .mongo.image.repository,
      tag: .mongo.image.tag,
    },
  },
  postgres: {
    enabled: .postgres.enabled,
    storageSize: .postgres.storageSize,
    storageClass: .postgres.storageClass,
    image: {
      repository: .postgres.image.repository,
      tag: .postgres.image.tag,
    },
    configs: {
      initPassword: .postgres.configs.initPassword,
    },
  },
  rabbit: {
    enabled: .rabbit.enabled,
    storageSize: .rabbit.storageSize,
    storageClass: .rabbit.storageClass,
    image: {
      repository: .rabbit.image.repository,
      tag: .rabbit.image.tag,
    },
  },
  redis: {
    enabled: .redis.enabled,
    storageSize: .redis.storageSize,
    storageClass: .redis.storageClass,
    image: {
      repository: .redis.image.repository,
      tag: .redis.image.tag,
    },
  },
  nats: {
    enabled: .nats.enabled,
    image: {
      repository: .nats.image.repository,
      tag: .nats.image.tag,
    },
  },
}'
