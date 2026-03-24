#!/bin/bash

read -p "Deploy Grafana and Loki? [y/N] " answer
case "$answer" in
  [yY][eE][sS]|[yY])
    docker compose -f grafana/docker-compose.yaml up -d
    docker compose -f loki/docker-compose.yaml up -d
    ;;
  *)
    echo "Aborted."
    ;;
esac
