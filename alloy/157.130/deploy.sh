#!/bin/bash
# Deploys the 157.130 Alloy bundle (rich loki.process pipelines for
# SIP server, RAG app, Redis, Qdrant, Telegram bot).
#
# Usage: ./deploy.sh [--loki <backend_host>]
# If --loki is omitted you'll be prompted for the backend host.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../scripts/lib/deploy-common.sh"

resolve_backend_host "$@"
confirm_and_deploy "$SCRIPT_DIR/docker-compose.yaml" "Alloy (157.130)"
