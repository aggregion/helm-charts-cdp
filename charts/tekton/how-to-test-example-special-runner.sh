# install rabbitmq
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade --install -n app \
    --set persistence.size=100Mi \
    --set persistence.storageClass=fast.ru-3b \
    --set auth.username=admin \
    --set auth.password=secretpassword \
    rabbitmq bitnami/rabbitmq

# install tekton-pipelines
helm upgrade --install -n tekton-pipelines \
    --set cloudevent.enabled=true \
    --set cloudevent.webhookUrl=http://pipeline-watcher-pipelines-svc.pipelines.svc.cluster.local:9101/pipelines/events \
    --set controllerServiceAccount.create=true \
    --set webhookServiceAccount.create=true \
    tekton-pipelines ./pipeline-release

# install only watcher (runner and service account are disabled)
helm upgrade --install -n pipelines \
    --set watcher.image.tag=41d6a836 \
    --set watcher.configs.logLevel=trace \
    --set runner.enabled=false \
    --set serviceAccount.create=false \
    pipelines ./pipeline

# install runner and service account (watcher disabled)
helm upgrade --install -n pipelines \
    --set runner.image.tag=41d6a836 \
    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.app.svc.cluster.local:5672 \
    --set runner.configs.logLevel=trace \
    --set watcher.enabled=false \
    --set serviceAccount.create=true \
    --set runner.configs.pipelinesCreateQueueName=task-app1 \
    --set runner.configs.basePipelineOptions.namespace=pipelines \
    --set runner.configs.pipelines.debug-hasher.storageClassName=longhorn \
    --set runner.configs.pipelines.debug-cleanroom.storageClassName=longhorn \
    --set runner.configs.basePipelineOptions.annotations."aggregion.dev"/instance=app \
    app-pipelines ./pipeline

# install pipelnes and tasks
helm upgrade --install -n pipelines aggregion-pipelines ./aggregion

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
