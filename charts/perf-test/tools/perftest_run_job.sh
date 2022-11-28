#!/bin/sh

MAIN_NS=keycloak \
IMAGE=registry.aggregion.com/perftest/jmeter:master \
CSV="../data/cleanroom-datasets-as.tsv" \
HOST=dl.alfastrah.ru \
REALM=aggregion \
LOGIN=dmitrii.babich@aggregion.com \
INFLUX_HOST="influxdb-influxdb2" \
INFLUX_PORT=80 \
INFLUX_TOKEN="wWbiQ6QH1GFCiZA26yzjcNGAMAHnVp17" \
INFLUX_ORG_ID=9832e3e958eSb89 \
METRICS_HOST=perftest-perf-test-perfmon-collector \
./perf-test/tools/generate_job.sh | kubectl -n perftest apply -f -
