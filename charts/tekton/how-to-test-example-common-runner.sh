# install rabbitmq if needed
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

# install our services for tekton
# pwd=charts
helm upgrade --install -n pipelines \
    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.app.svc.cluster.local:5672 \
    --set runner.configs.basePipelineOptions.namespace=pipelines \
    --set runner.configs.logLevel=trace \
    --set runner.configs.pipelines.debugCleanroom.pipelineName=debug-cleanroom-pipeline-charts \
    --set runner.configs.pipelines.debugCleanroom.storageClassName=longhorn \
    --set runner.configs.pipelines.debugHasher.pipelineName=debug-hasher-pipeline-charts \
    --set runner.configs.pipelines.debugHasher.storageClassName=longhorn \
    --set runner.configs.pipelines.sconeCleanroom.pipelineName=scone-cleanroom-pipeline-charts \
    --set runner.configs.pipelinesCreateQueueName=create_pipeline_runner \
    --set runner.enabled=true \
    --set runner.image.tag=bcb186be \
    --set serviceAccount.create=true \
    --set watcher.configs.logLevel=trace \
    --set watcher.enabled=true \
    --set watcher.image.tag=bcb186be \
    pipelines ./pipeline

# install pipelnes and tasks
# pwd=charts/tekton/helm
helm upgrade --install -n pipelines \
    --set debugCleanroom.enclaveServiceBaseUrl=http://aggregion-cdp-enclave-cdp-test1.cdpstage-dmpd-918-test.svc.cluster.local:8010 \
    --set sconeCleanroom.casAddr=185.184.79.2:18765 \
    --set sconeCleanroom.casCommonSessionName=someid \
    --set sconeCleanroom.enabled=true \
    --set sconeCleanroom.enclaveServiceBaseUrl=http://aggregion-cdp-enclave-cdp-test1.cdpstage-dmpd-918-test.svc.cluster.local:8010 \
    --set sconeCleanroom.lasAddr=18766 \
    --set sconeCleanroom.scriptDownloader.debug=true \
    pipeline-charts ./aggregion
