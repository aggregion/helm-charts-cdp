# install
# create helm-postgres-backup-values.yaml
$ cat <<EOF>>helm-postgres-backup-values.yaml
metadataService:
  backup:
    enabled: true
  postgres:
    db: metadata
    # host: <servicename>.<namespace>.<svc>
    host: aggregion-externals-postgres-externals-stage1.stages.svc
    port: 5432
    password: postgres
    user: postgres

cronjob:
  suspend: false

image:
  repository: postgres
  pullPolicy: IfNotPresent
  tag: "13.5"

resources: {}
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector:
  backup_jobs: "true"
EOF

$ helm upgrade --install postgres-backup backupjobs/ --values helm-postgres-backup-values.yaml --namespace logs


# uninstall
$ helm uninstall postgres-backup -n logs



# Misc

# mandeep@FAEQWTCZ2U:~/aggregion/repo$ pwd
# /home/mandeep/aggregion/repo
# mandeep@FAEQWTCZ2U:~/aggregion/repo$ ls -l
# total 56
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 16 21:46 argo
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 18 15:36 argo-prod
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 10 17:33 backupjobs
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 10 17:36 check_pvc
# -rw-r--r-- 1 mandeep mandeep 12400 Feb 22 18:26 filebeat-7.17.3.tgz
# drwxr-xr-x 1 mandeep mandeep  4096 Jun  5 15:04 helm-charts-cdp
# -rw-r--r-- 1 mandeep mandeep   602 Jun  5 17:03 helm-values-backupjobs-values.yaml
# -rw-r--r-- 1 mandeep mandeep 14402 Nov 16  2022 kibana-8.5.1.tgz
# drwxr-xr-x 1 mandeep mandeep  4096 Jun  1 14:55 kube-bootstrap
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 22 23:08 kustomize
# -rw-r--r-- 1 mandeep mandeep 13823 Feb  7 17:49 logstash-7.17.3.tgz
# drwxr-xr-x 1 mandeep mandeep  4096 May 23 13:25 postgresBackup
# -rw-r--r-- 1 mandeep mandeep   213 Mar 10 17:33 pvc.yaml
# -rw-r--r-- 1 mandeep mandeep  1849 Mar 12 02:03 s3-deployment.yaml
# drwxr-xr-x 1 mandeep mandeep  4096 Mar 11 13:23 s3sync

# # Install
# mandeep@FAEQWTCZ2U:~/aggregion/repo$ helm upgrade --install postgres-backup backupjobs/ --values helm-values-backupjobs-values.yaml --namespace logs
# Release "postgres-backup" does not exist. Installing it now.
# NAME: postgres-backup
# LAST DEPLOYED: Mon Jun  5 16:59:36 2023
# NAMESPACE: logs
# STATUS: deployed
# REVISION: 1
# TEST SUITE: None
# NOTES:
# 1. Get the application URL by running these commands:

# #Uninstall
# mandeep@FAEQWTCZ2U:~/aggregion/repo$ helm uninstall postgres-backup -n logs
# release "postgres-backup" uninstalled
