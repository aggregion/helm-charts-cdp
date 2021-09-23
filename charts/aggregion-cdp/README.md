Aggregion CDP Chart
===================

All supported params in values.yaml


Example installation
====================

1. Create `somens` namespace.
```
$ kubectl create ns somens
```
1. Add the label `name` for created namespace with value of the same name as namespace.
```
$ kubectl label namespace somns name=somens
```
1. Add secret for registry. Use appropriated method from `../../k8s-registry-secret` in this repository.
1. Deploy externals to `somens` namespace. Use `aggregion-externals` chart for that (clickhouse, mongo, redis, rabbit).
   For production it would be better to use official repositories or use bare metal installation in fault-tolerance mode.
1. Install CDP.
```
$ export domain="demo.mydemo.k8s-cluster.aggregion.com"

$ helm install \
  -n somens \
  --set "providers={demo}" \
  --set "providerLinks[0].name=demo" \
  --set "providerLinks[0].url=http://enclave.${domain}" \
  --set "frontend.image.tag=feature-DMPD-918-story" \
  --set "frontend.ingress.hosts[0].host=${domain}" \
  --set "backend.image.tag=feature-DMPD-918-story" \
  --set "backend.dbseed.enabled=true" \
  --set "backend.dbseed.image.tag=latest" \
  --set "backend.configs.mongoUrl=mongodb://aggregion-externals-mongo-demo:27017/dmpdemo" \
  --set "backend.configs.rabbitmqUrl=amqp://aggregion-externals-rabbit-demo" \
  --set "backend.configs.redisHost=aggregion-externals-redis-demo" \
  --set "backend.configs.clickhouseHost=aggregion-externals-clickhouse-demo" \
  --set "backend.configs.clickhouseDb=dmpdemo" \
  --set "backend.configs.baseUrl=http://${domain}" \
  --set "backend.configs.accountName=demo" \
  --set "backend.configs.providerName=demo" \
  --set "backend.configs.eosNodeUrl=http://testnet.blockchain.dmp.aggregion.com:9999" \
  --set "backend.configs.eosWalletPub=1FXkd4xcXYWTivOaHAS6VzKbh+mcPQ0AE4ZJav28Pw==" \          ### Insert correct EOS public key
  --set "backend.configs.eosWalletPk=1FXkd4xcXYWTivOaHAS6VzKbh+mcPQ0AE4ZJav28Pw==" \           ### Insert correct EOS private key
  --set "enclave.ingress.hosts[0].host=enclave.${domain}" \
  --set "enclave.ingress.hosts[0].paths[0]=/" \
  --set "enclave.scripts.auditory=sha256-79f0f08e9d843ca5c9142d65a33690f7eff90fdb9328270bfc67a32f7f52af45" \
  --set "enclave.scripts.segment=sha256-ae6c1af1ebf6b44143c9bcfce9ed8d5c5031291c7d264a3154b99936b026d06a" \
  --set "enclave.scripts.statistics=sha256-652c1df657735c02ff329216dd0d935a529447facdcf5919db54ab873067ebc7" \
  demoprov \
  ../aggregion-cdp
```

TODO
====

- [ ] Add sgx encalve deployment.
- [ ] Add network policies.
