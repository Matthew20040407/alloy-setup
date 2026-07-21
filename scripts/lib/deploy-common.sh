#!/bin/bash
# Shared helpers for deploy-alloy.sh and alloy/<host>/deploy.sh.
# Not meant to be run directly — source it.

DEFAULT_BACKEND_HOST="192.168.157.169"

# resolve_backend_host "$@" — reads --loki <host> (or --loki=<host>) from the
# caller's args, prompts interactively if it's missing, and exports LOKI_URL
# / PROMETHEUS_URL so the alloy config's sys.env() calls can pick them up.
# Falls back to DEFAULT_BACKEND_HOST on an empty answer so old muscle-memory
# (just hitting enter) keeps working against the current backend.
resolve_backend_host() {
  local backend_host=""

  while [ $# -gt 0 ]; do
    case "$1" in
      --loki)
        backend_host="$2"
        shift 2
        ;;
      --loki=*)
        backend_host="${1#--loki=}"
        shift
        ;;
      *)
        shift
        ;;
    esac
  done

  if [ -z "$backend_host" ]; then
    read -p "Loki/Prometheus backend host [$DEFAULT_BACKEND_HOST]: " backend_host
    backend_host="${backend_host:-$DEFAULT_BACKEND_HOST}"
  fi

  export LOKI_URL="http://${backend_host}:3100/loki/api/v1/push"
  export PROMETHEUS_URL="http://${backend_host}:9090/api/v1/write"
}

# confirm_and_deploy <compose_file> <label> — [y/N] prompt, then
# `docker compose up -d`. Aborts cleanly on anything but yes.
confirm_and_deploy() {
  local compose_file="$1"
  local label="$2"

  read -p "Deploy ${label}? Backend: ${LOKI_URL} [y/N] " answer
  case "$answer" in
    [yY][eE][sS]|[yY])
      docker compose -f "$compose_file" up -d
      ;;
    *)
      echo "Aborted."
      ;;
  esac
}
