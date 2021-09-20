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
