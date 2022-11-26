#!/bin/sh

set -e

MAIN_NS=${MAIN_NS:=$1}
NS=${NS:=perftest}
NAME_POSTFIX=$(date +%s)
IMAGE=${IMAGE:=registry.aggregion.com/perftest/jmeter:master}
CSV=${CSV:="../data/cleanroom-datasets-aggtest.tsv"}
HOST=${HOST:="test1.dcp.bm.dev.aggregion.com"}

INFLUX_HOST=${INFLUX_HOST:=influxdb-influxdb}
INFLUX_PORT=${INFLUX_PORT:=8086}
INFLUX_TOKEN=${INFLUX_TOKEN:=""}
INFLUX_ORG_ID=${INFLUX_ORG_ID:=""}
INFLUX_BUCKET=${INFLUX_BUCKET:=jmeter}

METRICS_HOST=${METRICS_HOST:=perf-test-perfmon-collector}
METRICS_PORT=${METRICS_PORT:=80}

REALM=${REALM:=aggregion}
ISSUER=${ISSUER:=https://kc.$HOST/realms/$REALM}
ORIGIN=${ORIGIN:=https://$HOST}
LOGIN=${LOGIN:=user@login.com}

KC_PK=${KC_PK:=$(./get_kc_private_key.sh $MAIN_NS $REALM)}

KC_ACCESS=${KC_ACCESS:=$(./generate_kc_access.py -k "$KC_PK" -r "$REALM" -i "$ISSUER" -o "$ORIGIN" "$LOGIN")}

echo "
apiVersion: batch/v1
kind: Job
metadata:
  name: jmeter-test-${NAME_POSTFIX}
  namespace: ${NS}
spec:
  parallelism: 1
  completions: 1
  backoffLimit: 4
  template:
    spec:
      containers:
        - name: jmeter
          image: ${IMAGE}
          command:
            - jmeter
            - '-n'
            - '-t'
            - /scripts/runners/run-metrics-influx-export.jmx
            - '-Jagg-csv=${CSV}'
            - '-Jagg_server_host=${HOST}'
            - '-Jinflux_host=${INFLUX_HOST}'
            - '-Jinflux_port=${INFLUX_PORT}'
            - '-Jinflux_token=${INFLUX_TOKEN}'
            - '-Jinflux_org_id=${INFLUX_ORG_ID}'
            - '-Jinflux_bucket=${INFLUX_BUCKET}'
            - '-Jagg_kc_access=\"${KC_ACCESS}\"'
            - '-Jmetrics_host=${METRICS_HOST}'
            - '-Jmetrics_port=${METRICS_PORT}'
            - '-l /tmp/results.jtl'
          imagePullPolicy: Always
      restartPolicy: Never
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      imagePullSecrets:
        - name: regcred
      schedulerName: default-scheduler
"
