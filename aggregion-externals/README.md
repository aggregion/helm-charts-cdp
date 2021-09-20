Optional Chart
==============

Use it when you need to start CDP quickly.
It's not recommend to use it in the production. Use charts from official rep for this purpose.

All supported params in values.yaml


Example installation
====================

1. Create `somens` namespace.
```
$ kubectl create ns somens
```
1. Deploy externals to `somens` namespace (may use `--create-namespace` flag to skip above step).
```
$ helm install \
  -n somens \
  --set "mongo.enabled=true" \
  --set "mongo.storageSize=4G" \
  --set "redis.enabled=true" \
  --set "redis.storageSize=1G" \
  --set "rabbit.enabled=true" \
  --set "rabbit.storageSize=1G" \
  --set "clickhouse.enabled=true" \
  --set "clickhouse.storageSize=32G" \
  demo \
  ../aggregion-externals
```
