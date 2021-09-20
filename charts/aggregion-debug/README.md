Optional Chart
==============

Useful chart for developing and testing a cdp.

All supported params in values.yaml


Example installation
====================

1. Create `somens` namespace.
```
$ kubectl create ns somens
```
1. Deploy debug to `somens` namespace (may use `--create-namespace` flag to skip above step).
```
$ helm install \
  -n somens \
  --set "mailcatcher.enabled=true" \
  demo \
  ../aggregion-debug
```
