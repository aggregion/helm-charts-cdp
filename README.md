Helm Charts for sgx-matrix monitoring via prometheus
===================

make sure prometheus read from files:

```
--collector.textfile.directory=/host/root/var/tmp/sgx/
```

```
helm upgrade --install sgx-matrix sgx-matrix/ --namespace monitoring --values sgx-matrix-values.yaml
```

