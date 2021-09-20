Helm Charts for CDP
===================

Installation
============

1. Create a namespace.
1. Create docker registry secret there.
1. (Optional step) Install `./aggregion-externals` chart. You may use bare metal databases and mq for that, don't forget to configure this in `./aggregion-cdp` chart.
1. Install `./aggregion-cdp` chart.
1. Install `./aggregion-dc` chart.
