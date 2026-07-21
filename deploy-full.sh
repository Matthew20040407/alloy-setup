#!/bin/bash
# Deploys the all-in-one observability stack (Loki + Prometheus + Grafana)
# from full_obs_stack.yaml. This is the main obs dashboard box.
#
# Do not also run the per-service Composes (loki/, grafana/, prometheus/)
# against the same host — they don't share full_obs_stack.yaml's network.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

read -p "Deploy full observability stack (Loki + Prometheus + Grafana)? [y/N] " answer
case "$answer" in
  [yY][eE][sS]|[yY])
    docker compose -f "$SCRIPT_DIR/full_obs_stack.yaml" up -d
    ;;
  *)
    echo "Aborted."
    ;;
esac
