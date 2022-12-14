#!/bin/bash

# pip3 install yq

cd $(dirname $0)

cat ../../charts/aggregion-cdp/values.yaml | yq -y '{
  gatekeeper: {
    enabled: .gatekeeper.enabled,
    config: {
      clientId: .gatekeeper.config.clientId,
      clientSecret: .gatekeeper.config.clientSecret,
      discoveryUrl: .gatekeeper.config.discoveryUrl,
      encryptionKey: .gatekeeper.config.encryptionKey,
      redirectionUrl: .gatekeeper.config.redirectionUrl,
      verbose: .gatekeeper.config.verbose,
    }
  },
  atlas: {
    baseUrl: .atlas.baseUrl,
    auth: .atlas.auth,
  },
  frontend: {
    enabled: .frontend.enabled,
    image: {
      repository: .frontend.image.repository,
      tag: .frontend.image.tag,
    },
    configs: {
      currency: .frontend.configs.currency
    },
    ingress: {
      enabled: .frontend.ingress.enabled,
      hosts: .frontend.ingress.hosts,
    },
  },
  backend: {
    enabled: .backend.enabled,
    image: {
      repository: .backend.image.repository,
      tag: .backend.image.tag,
    },
    crond: {
      image: {
        repository: .backend.crond.image.repository,
        tag: .backend.crond.image.tag,
      },
    },
    datalabProxy: {
      image: {
        repository: .backend.datalabProxy.image.repository,
        tag: .backend.datalabProxy.image.tag,
      },
    },
    dbseed: {
      enabled: .backend.dbseed.enabled,
      image: {
        repository: .backend.dbseed.image.repository,
        tag: .backend.dbseed.image.tag,
      },
    },
    configs: {
      mongoUrl: .backend.configs.mongoUrl,
      rabbitmqUrl: .backend.configs.rabbitmqUrl,
      redisHost: .backend.configs.redisHost,
      clickhouseHost: .backend.configs.clickhouseHost,
      clickhousePort: .backend.configs.clickhousePort,
      clickhouseDb: .backend.configs.clickhouseDb,
      clickhouseUser: .backend.configs.clickhouseUser,
      clickhousePassword: .backend.configs.clickhousePassword,
      dataStorageClass: .backend.configs.dataStorageClass,
      dataStorageSize: .backend.configs.dataStorageSize,
      accessFromFrontendEnabled: .backend.configs.accessFromFrontendEnabled,
      dataserviceViaFrontendEnabled: .backend.configs.dataserviceViaFrontendEnabled,
      logLevel: .backend.configs.logLevel,
      migrationEnabled: .backend.configs.migrationEnabled,
      serviceMatchingStatusWatcherEnabled: .backend.configs.serviceMatchingStatusWatcherEnabled,
      serviceMatchingStatusResponseWatcherEnabled: .backend.configs.serviceMatchingStatusResponseWatcherEnabled,
      serviceDatasetUploaderEnabled: .backend.configs.serviceDatasetUploaderEnabled,
      serviceBlockchainUpdaterEnabled: .backend.configs.serviceBlockchainUpdaterEnabled,
      serviceSegmentsEnabled: .backend.configs.serviceSegmentsEnabled,
      servicePanelSegmentUploaderEnabled: .backend.configs.servicePanelSegmentUploaderEnabled,
      servicePipelineDebugHasherStatusWatcherEnabled: .backend.configs.servicePipelineDebugHasherStatusWatcherEnabled,
      servicePipelineDebugCleanroomStatusWatcherEnabled: .backend.configs.servicePipelineDebugCleanroomStatusWatcherEnabled,
      dmpSecret: .backend.configs.dmpSecret,
      jwtSecret: .backend.configs.jwtSecret,
      baseUrl: .backend.configs.baseUrl,
      alarmEmail: .backend.configs.alarmEmail,
      supportEmail: .backend.configs.supportEmail,
      email: .backend.configs.email,
      providerName: .backend.configs.providerName,
      providerInstanceId: .backend.configs.providerInstanceId,
      accountName: .backend.configs.accountName,
      eosNodeUrl: .backend.configs.eosNodeUrl,
      eosOrgId: .backend.configs.eosOrgId,
      eosWalletPub: .backend.configs.eosWalletPub,
      eosWalletPk: .backend.configs.eosWalletPk,
      eosWalletOwnerOrgId: .backend.configs.eosWalletOwnerOrgId,
      eosWalletOwnerPub: .backend.configs.eosWalletOwnerPub,
      eosWalletOwnerPk: .backend.configs.eosWalletOwnerPk,
      eosDecryptPk: .backend.configs.eosDecryptPk,
      datalabUsername: .backend.configs.datalabUsername,
      datalabPassword: .backend.configs.datalabPassword,
      datalabTemplates: .backend.configs.datalabTemplates,
      datalabPlatformId: .backend.configs.datalabPlatformId,
      datalabStorageSizeGb: .backend.configs.datalabStorageSizeGb,
      datalabCpuLimit: .backend.configs.datalabCpuLimit,
      datalabMemoryLimitGb: .backend.configs.datalabMemoryLimitGb,
      datalabDmpNamespace: .backend.configs.datalabDmpNamespace,
      datalabNamespace: .backend.configs.datalabNamespace,
      datalabOverwriteDomain: .backend.configs.datalabOverwriteDomain,
      datalabOverwritePort: .backend.configs.datalabOverwritePort,
      datalabWhiteIps: .backend.configs.datalabWhiteIps,
      datalabApiUrl: .backend.configs.datalabApiUrl,
      datalabApiVersion: .backend.configs.datalabApiVersion,
      datalabAuthUrl: .backend.configs.datalabAuthUrl,
      datalabWebhookUrl: .backend.configs.datalabWebhookUrl,
      datalabMaxVms: .backend.configs.datalabMaxVms,
      atlasUrl: .backend.configs.atlasUrl,
      dcUseExternalS3: .backend.configs.dcUseExternalS3,
      graphQLPlayground: .backend.configs.graphQLPlayground,
      gitlab: .backend.configs.gitlab,
      pipelineRunner: {
        debugMode: .backend.configs.pipelineRunner.debugMode,
        pipelines: {
          cleanroom: {
            namespace: .backend.configs.pipelineRunner.pipelines.cleanroom.namespace,
            pipelineName: .backend.configs.pipelineRunner.pipelines.cleanroom.pipelineName,
          },
        },
      },
    },
  },
  enclave: {
    enabled: .enclave.enabled,
    sgx: .enclave.sgx,
    scone: {
      enabled: .enclave.scone.enabled,
      debug: .enclave.scone.debug,
      espApiKey: .enclave.scone.espApiKey,
      espAddr: .enclave.scone.espAddr,
      lasPort: .enclave.scone.lasPort,
      lasHostPort: .enclave.scone.lasHostPort,
      heapSize: .enclave.scone.heapSize,
      lasImage: {
        repository: .enclave.scone.lasImage.repository,
        tag: .enclave.scone.lasImage.tag,
      },
    },
    imageServer: {
      repository: .enclave.imageServer.repository,
      tag: .enclave.imageServer.tag,
    },
    imageServices: {
      repository: .enclave.imageServices.repository,
      tag: .enclave.imageServices.tag,
    },
    configs: {
      dataserviceToken: .enclave.configs.dataserviceToken,
      authPrivateKey: .enclave.configs.authPrivateKey,
      datalabToken: .enclave.configs.datalabToken,
      dmpBaseURL: .enclave.configs.dmpBaseURL,
      dataserviceBaseURL: .enclave.configs.dataserviceBaseURL,
    },
    ingress: {
      enabled: .enclave.ingress.enabled,
      hosts: .enclave.ingress.hosts,
    },
  },
  dataservice: {
    enabled: .dataservice.enabled,
    imageApi: {
      repository: .dataservice.imageApi.repository,
      tag: .dataservice.imageApi.tag,
    },
    imageAtlasEntitySyncer: {
      repository: .dataservice.imageAtlasEntitySyncer.repository,
      tag: .dataservice.imageAtlasEntitySyncer.tag,
    },
    imageJobRunner: {
      repository: .dataservice.imageJobRunner.repository,
      tag: .dataservice.imageJobRunner.tag,
    },
    configAtlasSyncer: {
      enabled: .dataservice.configAtlasSyncer.enabled,
      cronjob: .dataservice.configAtlasSyncer.cronjob,
    },
    glossarySyncers: .dataservice.glossarySyncers,
    datasetLogsSyncers: .dataservice.datasetLogsSyncers,
    datasetDatasetSyncer: .dataservice.datasetDatasetSyncer,
    datasetDatasetUpdater: .dataservice.datasetDatasetUpdater,
    datasetInstanceSyncer: .dataservice.datasetInstanceSyncer,
    config: {
      accessToken: .dataservice.config.accessToken,
      logLevel: .dataservice.config.logLevel,
      mongoDbUri: .dataservice.config.mongoDbUri,
      tokenSecretKey: .dataservice.config.tokenSecretKey,
      tokenIssuer: .dataservice.config.tokenIssuer,
      bcmqPollingInterval: .dataservice.config.bcmqPollingInterval,
      bcmqLimit: .dataservice.config.bcmqLimit,
      trinoHost: .dataservice.config.trinoHost,
      trinoPort: .dataservice.config.trinoPort,
      rabbitmqUri: .dataservice.config.rabbitmqUri,
      endpoint: .dataservice.config.endpoint,
      clickhouseUseDirectConnection: .dataservice.config.clickhouseUseDirectConnection,
    },
  },
  metadataSeed: {
    enabled: .metadataSeed.enabled,
    cronjob: .metadataSeed.cronjob,
    image: {
      repository: .metadataSeed.image.repository,
      tag: .metadataSeed.image.tag,
    },
    config: {
      logLevel: .metadataSeed.config.logLevel,
      dmpBackendBaseUrl: .metadataSeed.config.dmpBackendBaseUrl,
    },
  },
  authservice: {
    enabled: .authservice.enabled,
    image: {
      repository: .authservice.image.repository,
      tag: .authservice.image.tag,
    },
    config: {
      logLevel: .authservice.config.logLevel,
      mongoDbUri: .authservice.config.mongoDbUri,
      jwtSecretKey: .authservice.config.jwtSecretKey,
    },
  },
}'
