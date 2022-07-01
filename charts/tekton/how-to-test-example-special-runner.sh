export INSTANCE=app1

# install rabbitmq
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install -n app \
    --set auth.password=secretpassword \
    --set auth.username=admin \
    --set persistence.size=100Mi \
    --set persistence.storageClass=fast.ru-3b \
    rabbitmq bitnami/rabbitmq

# install tekton-pipelines
# pwd=charts/tekton/helm
helm upgrade --install -n tekton-pipelines \
    --set cloudevent.enabled=true \
    --set cloudevent.webhookUrl=http://pipeline-watcher-pipelines-svc.pipelines.svc.cluster.local:9101/pipelines/events \
    --set controllerServiceAccount.create=true \
    --set pruner.backoffLimit=24 \
    --set webhookServiceAccount.create=true \
    tekton-pipelines ./pipeline-release

# install only watcher (runner and service account are disabled)
# pwd=charts
helm upgrade --install -n pipelines \
    --set runner.enabled=false \
    --set serviceAccount.create=false \
    --set watcher.configs.logLevel=trace \
    --set watcher.image.tag=bcb186be \
    pipelines ./pipeline

# install runner and service account (watcher disabled)
# pwd=charts
helm upgrade --install -n pipelines \
    --set "runner.configs.basePipelineOptions.annotations.aggregion\.dev/instance=$INSTANCE" \
    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.app.svc.cluster.local:5672 \
    --set runner.configs.basePipelineOptions.namespace=pipelines \
    --set runner.configs.logLevel=trace \
    --set runner.configs.pipelines.debugCleanroom.pipelineName=debug-cleanroom-$INSTANCE-agg-pipelines \
    --set runner.configs.pipelines.debugCleanroom.storageClassName=longhorn \
    --set runner.configs.pipelines.debugHasher.pipelineName=debug-hasher-$INSTANCE-agg-pipelines \
    --set runner.configs.pipelines.debugHasher.storageClassName=longhorn \
    --set runner.configs.pipelines.sconeCleanroom.pipelineName=scone-cleanroom-$INSTANCE-agg-pipelines \
    # runner.configs.pipelinesCreateQueueName must be equals to CDP.backend.configs.pipelineRunner.queue
    --set runner.configs.pipelinesCreateQueueName=create_pipeline_runner \
    --set runner.image.tag=bcb186be \
    --set serviceAccount.create=true \
    --set watcher.enabled=false \
    $INSTANCE-pipelines ./pipeline

# install pipelnes and tasks
# pwd=charts/tekton/helm
helm upgrade --install -n pipelines \
    --set debugCleanroom.enclaveServiceBaseUrl=http://aggregion-cdp-enclave-cdp-test1.cdpstage-dmpd-918-test.svc.cluster.local:8010 \
    --set sconeCleanroom.casAddr=185.184.79.2:18765 \
    # sconeCleanroom.casCommonSessionName from ESP
    --set sconeCleanroom.casCommonSessionName=someid \
    --set sconeCleanroom.enabled=true \
    --set sconeCleanroom.enclaveServiceBaseUrl=http://aggregion-cdp-enclave-cdp-test1.cdpstage-dmpd-918-test.svc.cluster.local:8010 \
    --set sconeCleanroom.lasAddr=18766 \
    --set sconeCleanroom.scriptDownloader.debug=true \
    $INSTANCE-agg-pipelines ./aggregion

: '
{
  "namespace": "pipelines",
  "pvcName": "app1-hasher-1-1-pvc",
  "pvcSize": "10Mi",
  "storageClassName": "fast.ru-3b",
  "pipelineName": "debug-hasher",
  "pipelineRunName": "app1-hasher-1-1",
  "serviceAccountName": "app1-runner-sa",
  "params": [{
    "name": "message",
    "value": "DEBUG"
  }],
  "volumes": [{
    "name": "vol",
    "persistentVolumeClaim": {
      "claimName": "app1-hasher-1-1-pvc"
    }
  }],
  "amqpURI": "amqp://admin:secretpassword@rabbitmq.app.svc.cluster.local:5672",
  "amqpReplyTo": "status-app1",
  "timeout": "1h0m0s"
}
'''
