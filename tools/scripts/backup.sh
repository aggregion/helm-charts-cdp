#!/bin/sh
mkdir -p /home/backup_deploy/bckp`date +%Y-%m-%d`
cp -r /home/helm/helm-charts-cdp-master/charts/*.* /home/backup_deploy/bckp`date +%Y-%m-%d`
