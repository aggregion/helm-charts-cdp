# Aggregion Deploy Controller Chart

## To Deploy all in-one

1. Create `somens` namespace.
```
$ kubectl create ns deploy-controller
```
1. Add secret for registry. Use appropriated method from `../../k8s-registry-secret` in this repository.
1. Deploy externals to `deploy-controller` namespace. Use `aggregion-externals` chart for that (postgres, redis, nats).
   For production it would be better to use official repositories or use bare metal installation in fault-tolerance mode.
1. Create schemas in postgres database:
For example,
```$ kubectl -n <<<CREATED NAMESPACE>>> exec -ti aggregion-externals-postgres-<<< POD-SUFFIX (kubectl -n .. get pods) >>> -- psql -U postgres```
Execute the script:
```
create schema auth;
create schema deployer_app;
create schema deployer_datalab;
create schema notification;
create schema platform;
create schema provision;
create schema trigger;
create schema vcsint;
```
1. Install DC.
```
$ export api="dc.mydemo.k8s-cluster.aggregion.com"

$ helm install \
  -n somens \
  --set "agentk8s.configs.authJwtSecret=OS2iXMSjBNNpB6SX0uAiJ2KaCuEkYsfcozvD4vq8KA==" \  ### Generate your own
  --set "dc.configs.cipherSecret=EyNXDClu2lgLYbRYG5hxQLxsZKHxweFQr7HN0dz21A==" \         ### Generate your own
  --set "dc.configs.authJwtSecret=MGCwIzhaRD8A+nB75WPA+vtvbUy0XehdvL2I0jGPWA==" \        ### Generate your own
  --set "dc.configs.tykGwSecret=YpR+6lBrk3NkhGn+EdvCoVOA+XRCaUCaOA9kisvbaQ==" \          ### Generate your own
  --set "dc.configs.databaseHost=aggregion-externals-postgres-demo" \
  --set "dc.configs.gwRedisHost=aggregion-externals-redis-demo" \
  --set "dc.configs.redisUrl=redis://aggregion-externals-redis-demo:6379" \
  --set "dc.configs.natsUrl=nats://aggregion-externals-nats-demo:4222" \
  --set "dc.deployerApp.enabled=true" \
  --set "dc.deployerDatalab.enabled=true" \
  --set "dc.trigger.enabled=true" \
  --set "dc.ingress.hosts[0].host=${api}" \
  --set "dc.ingress.hosts[0].paths={/}" \
  demodc \
  ../aggregion-dc
```


## To Deploy k8s Agent in Kubernetes only

TODO


## DC Configuration through API

TODO


## TODO

- [ ] Add network policies.
