Helm Charts for CDP
===================

Add Aggregion CDP Charts repository to Helm repos:

```
helm repo add aggregioncdp https://aggregion.github.io/helm-charts-cdp/charts
```

[View on GitHub](https://github.com/aggregion/helm-charts-cdp)


Installation
============

1. Create a namespace.
1. Create docker registry secret there.
1. (Optional step) Install `aggregion-externals` chart. You may use bare metal databases and mq for that, don't forget to configure this in `aggregion-cdp` chart.
1. Install `aggregion-cdp` chart.
1. Install `aggregion-dc` chart.

Helm Charts for sgx-matrix monitoring via prometheus
===================

Install chart with command below
```
helm upgrade --install sgx-matrix sgx-matrix/ --namespace monitoring --values sgx-matrix-values.yaml
```
now update node-exporters to make sure prometheus read from files, append "--collector.textfile.directory=/host/root/var/tmp/" in arguments to node-exporter in
kube-bootstrap 

```
...
  containers:
    - name: node-exporter
      image: quay.io/prometheus/node-exporter:v1.3.1
      args:
        - '--path.procfs=/host/proc'
        - '--path.sysfs=/host/sys'
        - '--path.rootfs=/host/root'
        - '--web.listen-address=[$(HOST_IP)]:9100'
        - >-
          --collector.filesystem.ignored-mount-points=^/(dev|proc|sys|var/lib/docker/.+|var/lib/kubelet/.+)($|/)
        - >-
          --collector.filesystem.ignored-fs-types=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$
        - '--collector.textfile.directory=/host/root/var/tmp/'
...
```

then execute below command
```
helm upgrade --install --namespace monitoring elasticsearch-exporter prometheus-community/prometheus-elasticsearch-exporter -f helm-values-elasticsearch-exporter.yaml
```


Once all tasks are executed properly, prometheus start getting following parameters.
```
sgx_init_enclaves
sgx_loaded_back
sgx_nr_alloc_pages
sgx_nr_enclaves
sgx_nr_epc_sections
sgx_nr_evicted
sgx_nr_free_pages
sgx_nr_high_pages
sgx_nr_low_pages
sgx_nr_marked_old
sgx_nr_reclaim
sgx_nr_total_epc_pages
```
