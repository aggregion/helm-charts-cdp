# install rabbitmq
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade -n infra \
    --set persistence.size=100Mi \
    --set persistence.storageClass=fast.ru-3b \
    --set auth.username=admin \
    --set auth.password=secretpassword \
    rabbitmq bitnami/rabbitmq

# install tekton-pipelines
helm upgrade --install -n tekton-pipelines \
    --set cloudevent.enabled=true \
    --set cloudevent.webhookUrl=http://pipeline-watcher-pipelines.pipelines.svc.cluster.local:9101/pipelines/events \
    --set controllerServiceAccount.create=true \
    --set webhookServiceAccount.create=true \
    tekton-pipelines ./pipeline-release

# install runner, watcher and service account
helm upgrade --install -n pipelines \
    --set runner.image.tag=41d6a836 \
    --set watcher.image.tag=41d6a836 \
    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.infra.svc.cluster.local:5672 \
    --set runner.configs.logLevel=trace \
    --set watcher.configs.logLevel=trace \
    --set serviceAccount.create=true \
    pipelines ./pipeline

# install pipelnes and tasks
helm upgrade --install -n pipelines aggregion-pipelines ./aggregion

'''
{
  "namespace": "pipelines",
  "pvcName": "hasher-1-1-pvc",
  "pvcSize": "10Mi",
  "storageClassName": "fast.ru-3b",
  "pipelineName": "debug-hasher",
  "pipelineRunName": "hasher-1-1",
  "serviceAccountName": "tekton-pipeline-runner",
  "params": [{
    "name": "message",
    "value": "DEBUG"
  }],
  "volumes": [{
    "name": "vol",
    "persistentVolumeClaim": {
      "claimName": "hasher-1-1-pvc"
    }
  }],
  "amqpURI": "amqp://admin:secretpassword@rabbitmq.infra.svc.cluster.local:5672",
  "amqpReplyTo": "pipeline-statuses",
  "timeout": "1h0m0s"
}
'''
