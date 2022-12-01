#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/atlas/values.yaml | yq -y '{
  atlas: {
    enabled: .atlas.enabled,
    storageSize: .atlas.storageSize,
    storageClass: .atlas.storageClass,
    image: {
      repository: .atlas.image.repository,
      tag: .atlas.image.tag,
    },
    ingress: {
      hosts: .atlas.ingress.hosts,
    },
    resources: .atlas.resources,
  },
  cassandra: {
    storageSize: .cassandra.storageSize,
    storageClass: .cassandra.storageClass,
    image: {
      repository: .cassandra.image.repository,
      tag: .cassandra.image.tag,
    },
    resources: .cassandra.resources,
  },
  hadoop: {
    dataStorageSize: .hadoop.dataStorageSize,
    nameStorageSize: .hadoop.nameStorageSize,
    hdfsStorageSize: .hadoop.hdfsStorageSize,
    yarnStorageSize: .hadoop.yarnStorageSize,
    storageClass: .hadoop.storageClass,
    image: {
      repository: .hadoop.image.repository,
      tag: .hadoop.image.tag,
    },
    resources: .hadoop.resources,
  },
  hadoopInit: {
    image: {
      repository: .hadoopInit.image.repository,
      tag: .hadoopInit.image.tag,
    },
    resources: .hadoopInit.resources,
  },
  hbase: {
    storageClass: .hbase.storageClass,
  },
  hbaseMaster: {
    storageSize: .hbaseMaster.storageSize,
    image: {
      repository: .hbaseMaster.image.repository,
      tag: .hbaseMaster.image.tag,
    },
    resources: .hbaseMaster.resources,
  },
  hbaseRegion: {
    storageSize: .hbaseRegion.storageSize,
    image: {
      repository: .hbaseRegion.image.repository,
      tag: .hbaseRegion.image.tag,
    },
    resources: .hbaseRegion.resources,
  },
  kafka: {
    storageSize: .kafka.storageSize,
    storageClass: .kafka.storageClass,
    image: {
      repository: .kafka.image.repository,
      tag: .kafka.image.tag,
    },
    resources: .kafka.resources,
  },
  kafkaInit: {
    image: {
      repository: .kafkaInit.image.repository,
      tag: .kafkaInit.image.tag,
    },
    resources: .kafkaInit.resources,
  },
  solr: {
    storageSize: .solr.storageSize,
    storageClass: .solr.storageClass,
    image: {
      repository: .solr.image.repository,
      tag: .solr.image.tag,
    },
    resources: .solr.resources,
  },
  solrInit: {
    image: {
      repository: .solrInit.image.repository,
      tag: .solrInit.image.tag,
    },
    resources: .solrInit.resources,
  },
  zookeeper: {
    storageSize: .zookeeper.storageSize,
    storageClass: .zookeeper.storageClass,
    image: {
      repository: .zookeeper.image.repository,
      tag: .zookeeper.image.tag,
    },
    resources: .zookeeper.resources,
  },
}'
