# install
# create helm-mongo-backup-values-<dbname>.yaml
$ cat <<EOF>>helm-mongo-backup-values-<dbname>.yaml
mongobackup:
  enabled: true
  namespace: stages                                     # where service is available
  endpoint: aggregion-externals-mongo-externals-stage1  # service for mongo
  db: <dbname>                                          # set db name i.e. <dmp|ds|auth>
  port: 27017                                           # check port, where service is listening

cronjob:
  suspend: false

image:
  repository: mongo
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "4.4.18"

resources:
  limits:
    cpu: 1000m
    memory: 512Mi
  requests:
    cpu: 100m
    memory: 128Mi

nodeSelector:
  backup_jobs: "true"
EOF

# test installation
$ helm upgrade --install --dry-run --namespace backups mongo-dmp-backup  mongo/ --values helm-mongo-backup-values-dmp.yaml
$ helm upgrade --install --dry-run --namespace backups mongo-ds-backup   mongo/ --values helm-mongo-backup-values-ds.yaml
$ helm upgrade --install --dry-run --namespace backups mongo-auth-backup mongo/ --values helm-mongo-backup-values-auth.yaml

# install
$ helm upgrade --install --namespace backups mongo-dmp-backup  mongo/ --values helm-mongo-backup-values-dmp.yaml
$ helm upgrade --install --namespace backups mongo-ds-backup   mongo/ --values helm-mongo-backup-values-ds.yaml
$ helm upgrade --install --namespace backups mongo-auth-backup mongo/ --values helm-mongo-backup-values-auth.yaml

# uninstall
$ helm -n backups uninstall mongo-dmp-backup
$ helm -n backups uninstall mongo-ds-backup
$ helm -n backups uninstall mongo-auth-backup
