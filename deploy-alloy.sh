#!/bin/bash
# Deploys the generic Alloy collector (alloy/config.alloy).
# For a host-specific config, use alloy/<server_ip>/deploy.sh instead.
#
# Usage: ./deploy-alloy.sh [--loki <backend_host>]
# If --loki is omitted you'll be prompted for the backend host.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/scripts/lib/deploy-common.sh"

resolve_backend_host "$@"
confirm_and_deploy "$SCRIPT_DIR/alloy/docker-compose.yaml" "Alloy (generic)"
