#!/bin/bash

pip3 install yq

cat ../charts/tekton/helm/aggregion/values.yaml | yq -y '{
  sgx: {
    device: .sgx.device,
  },
  debugCleanroom: {
    enabled: false,
  },
  debugHasher: {
    enabled: false,
  },
  sconeCleanroom: {
    enabled: true,
    enclaveServiceBaseUrl: .sconeCleanroom.enclaveServiceBaseUrl,
    casAddr: .sconeCleanroom.casAddr,
    casCommonSessionName: .sconeCleanroom.casCommonSessionName,
    lasPort: .sconeCleanroom.lasPort,
    runMode: .sconeCleanroom.runMode,
    dcpBaseUrl: .sconeCleanroom.dcpBaseUrl,
    datasetDownloader: {
      sconeHeap: .sconeCleanroom.datasetDownloader.sconeHeap,
      resources .sconeCleanroom.datasetDownloader.resources,
    },
    pythonRunner: {
      sconeHeap: .sconeCleanroom.pythonRunner.sconeHeap,
      resources .sconeCleanroom.pythonRunner.resources,
    },
    resultPublisher: {
      sconeHeap: .sconeCleanroom.resultPublisher.sconeHeap,
      resources .sconeCleanroom.resultPublisher.resources,
    },
    scriptDownloader: {
      sconeHeap: .sconeCleanroom.scriptDownloader.sconeHeap,
      resources .sconeCleanroom.scriptDownloader.resources,
    },
  },
}'
