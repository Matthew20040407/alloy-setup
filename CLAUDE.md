# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-hosted observability stack split across three independently-deployable Docker Compose units (Alloy → Loki/Prometheus → Grafana). There is no application code — only collector configs, Compose files, and dashboards.

## Deployment topology

Two distinct deployment shapes coexist in the tree, and the difference matters:

1. **Per-service Compose files** under `loki/`, `grafana/`, `prometheus/`, `alloy/` — used by the `deploy-*.sh` scripts. Each runs in its own Compose project with no shared network. Services find each other only via host IPs hard-coded into configs.
2. **`full_obs_stack.yaml`** at the repo root — an all-in-one stack (Loki + Prometheus + Grafana, no Alloy) that wires them onto a shared `observability` bridge network. This is an alternative to running the per-service Composes; do not run both against the same host.

The `deploy-grafana-loki.sh` / `deploy-alloy.sh` scripts only cover the per-service shape. There is no script for `full_obs_stack.yaml`.

## Alloy config split — read this before editing

`alloy/` contains **per-host configs** that are not interchangeable:

- `alloy/config.alloy` + `alloy/docker-compose.yaml` — the generic variant the `deploy-alloy.sh` script mounts. Minimal: system logs, Docker logs, cAdvisor → remote Prometheus + Loki.
- `alloy/157.130/config.alloy` — host-specific config for the `157.130` machine with rich `loki.process` pipelines for SIP server, RAG app, Redis, Qdrant, Telegram bot, and cAdvisor metric filtering. **No bundled Compose** — uses the generic `alloy/docker-compose.yaml`; swap the config over `alloy/config.alloy` or edit the mount.
- `alloy/157.127/` — host-specific bundle for the `157.127` GPU machine. Has its **own** `docker-compose.yaml` that runs Alloy alongside an `nvcr.io/nvidia/k8s/dcgm-exporter` sidecar for per-container GPU metrics. Also collects host metrics via `prometheus.exporter.unix` and standard cAdvisor + logs. Deploy with `docker compose -f alloy/157.127/docker-compose.yaml up -d` — the `deploy-alloy.sh` script does **not** cover it.

When asked to change "the Alloy config," ask which host. They drift independently.

## Hard-coded endpoints

Remote write/push URLs are embedded as literal IPs in the Alloy configs — there is no env var substitution. Update both `loki.write` and `prometheus.remote_write` blocks together when relocating the backend.

## Deploy commands

```bash
./deploy-grafana-loki.sh   # brings up grafana and loki (per-service Composes)
./deploy-alloy.sh          # brings up alloy with alloy/config.alloy
```

Both prompt `[y/N]` before running `docker compose up -d`. There is no teardown script — use `docker compose -f <path> down` directly.

To deploy Prometheus standalone: `docker compose -f prometheus/docker-compose.yaml up -d` (no script exists).

## Grafana defaults

Admin login is `admin` / `Grafana-123` (set in the Compose env). The dashboard JSON for the 157.130 host lives at `grafana/dashboard/157.130.json` and is not auto-provisioned — import it manually in the UI, or wire up `grafana/provisioning/` (the path is mounted but currently empty).

## Linting

`.trunk/trunk.yaml` configures `trunk` with yamllint, markdownlint, shellcheck, and others. Run `trunk check` if available; configs live in `.trunk/configs/`.
