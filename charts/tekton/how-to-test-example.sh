helm upgrade --kubeconfig ~/Downloads/keeley.yaml -n infra \
    --set persistence.size=100Mi \
    --set persistence.storageClass=fast.ru-3b \
    --set auth.username=admin \
    --set auth.password=secretpassword \
    rabbitmq bitnami/rabbitmq

helm upgrade --install --kubeconfig ~/Downloads/keeley.yaml -n tekton-pipelines \
    --set cloudevent.enabled=true \
    --set cloudevent.webhookUrl=http://pipeline-watcher-pipelines.pipelines.svc.cluster.local/pipelines/events \
    tekton-pipelines ./pipeline-release

helm upgrade --install -n pipelines --kubeconfig ~/Downloads/keeley.yaml \
    --set runner.image.tag=f6370102 \
    --set watcher.image.tag=f6370102 \
    --set runner.configs.amqpUrl=amqp://admin:secretpassword@rabbitmq.infra.svc.cluster.local:5672 \
    pipelines ./pipeline

helm upgrade --kubeconfig ~/Downloads/keeley.yaml --install -n pipelines aggregion-pipelines ./aggregion

'''
{
  "namespace": "pipelines",
  "pvcName": "hasher-1-1-pvc",
  "pvcSize": "10Mi",
  "storageClassName": "fast.ru-3b",
  "pipelineName": "hasher",
  "pipelineRunName": "hasher-1-1",
  "serviceAccountName": "tekton-pipeline-runner",
  "params": [{
    "name": "message",
    "value": "DEBUG"
  }],
  "volumes": [{
    "name": "vol",
    "value": {
      "properties": {
        "claimName": "hasher-1-1-pvc"
      }
    }
  }]
}
'''
