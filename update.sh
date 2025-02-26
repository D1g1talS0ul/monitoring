#!/bin/bash
# https://grafana.com/docs/grafana-cloud/send-data/metrics/metrics-prometheus/prometheus-config-examples/docker-compose-linux/
# https://github.com/grafana/alloy/blob/main/example/README.md

docker compose --profile=monitoring down
docker compose --profile=monitoring up --build --detach
