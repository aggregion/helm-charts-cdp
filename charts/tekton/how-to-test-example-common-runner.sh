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
helm upgrade --install -n tekton-pipelines \
    --set cloudevent.enabled=true \
    --set cloudevent.webhookUrl=http://pipeline-watcher-pipelines-svc.pipelines.svc.cluster.local:9101/pipelines/events \
    --set controllerServiceAccount.create=true \
    --set pruner.backoffLimit=24 \
    --set webhookServiceAccount.create=true \
    tekton-pipelines ./pipeline-release

# install only watcher (runner and service account are disabled)
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
    --set runner.configs.pipelinesCreateQueueName=task-$INSTANCE \
    --set runner.enabled=true \
    --set runner.image.tag=bcb186be \
    --set serviceAccount.create=true \
    --set watcher.configs.logLevel=trace \
    --set watcher.enabled=true \
    --set watcher.image.tag=bcb186be \
    pipelines ./pipeline

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
