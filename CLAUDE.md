# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A self-hosted observability stack split across three independently-deployable Docker Compose units (Alloy → Loki/Prometheus → Grafana). There is no application code — only collector configs, Compose files, and dashboards.

## Deployment topology

Two distinct deployment shapes coexist in the tree, and the difference matters:

1. **Per-service Compose files** under `loki/`, `grafana/`, `prometheus/` — no script deploys these as a unit anymore except `deploy-grafana-loki.sh` (grafana+loki only; Prometheus standalone has no script). Each runs in its own Compose project with no shared network.
2. **`full_obs_stack.yaml`** at the repo root — the primary way to stand up the backend: an all-in-one stack (Loki + Prometheus + Grafana, no Alloy) on a shared `observability` bridge network. Deployed via `./deploy-full.sh`. This is an alternative to the per-service Composes; do not run both against the same host.

`alloy/` is never part of either backend shape — it's the collector, deployed separately (and usually on a different machine) via `deploy-alloy.sh` or `alloy/<server_ip>/deploy.sh`.

## Alloy config split — read this before editing

`alloy/` contains **per-host configs** that are not interchangeable, but every variant is now a self-contained bundle: its own `config.alloy`, `docker-compose.yaml`, and `deploy.sh`.

- `alloy/config.alloy` + `alloy/docker-compose.yaml` + `alloy/deploy.sh` — the generic variant, deployed from the repo root via `./deploy-alloy.sh`. Minimal: system logs, Docker logs, cAdvisor → remote Prometheus + Loki.
- `alloy/157.130/` — host-specific bundle for the `157.130` machine with rich `loki.process` pipelines for SIP server, RAG app, Redis, Qdrant, Telegram bot, and cAdvisor metric filtering. Has its own `docker-compose.yaml` (a copy of the generic one) and `deploy.sh` — no longer borrows the generic Compose file.
- `alloy/157.127/` — host-specific bundle for the `157.127` GPU machine. Its `docker-compose.yaml` runs Alloy alongside an `nvcr.io/nvidia/k8s/dcgm-exporter` sidecar for per-container GPU metrics, plus host metrics via `prometheus.exporter.unix` and standard cAdvisor + logs.

Deploy any bundle with `cd alloy/<server_ip> && ./deploy.sh --loki <backend_host>`. When asked to change "the Alloy config," ask which host. They drift independently.

## Backend endpoint resolution

Remote write/push URLs are **not** hard-coded literals anymore. Each `config.alloy` reads them via `coalesce(sys.env("LOKI_URL"), "http://<default>...")` / same for `PROMETHEUS_URL` — env var first, falling back to the current default backend (`192.168.157.169`) if unset. The deploy scripts set `LOKI_URL`/`PROMETHEUS_URL` from the `--loki <backend_host>` flag (prompting if omitted) via `scripts/lib/deploy-common.sh`, and the `docker-compose.yaml` files pass them through with a bare `environment: - LOKI_URL` entry. When relocating the backend, there's nothing to edit in the `.alloy` files — just deploy with a different `--loki` value. Only bump the fallback default in all three `config.alloy` files if the *default* backend itself moves permanently.

## Deploy commands

```bash
./deploy-full.sh                              # backend: Loki + Prometheus + Grafana (full_obs_stack.yaml)
./deploy-alloy.sh --loki <backend_host>        # generic Alloy collector
cd alloy/<server_ip> && ./deploy.sh --loki <backend_host>   # host-specific Alloy bundle
./deploy-grafana-loki.sh                       # legacy: per-service grafana+loki only
```

All prompt `[y/N]` before running `docker compose up -d`; the two Alloy variants also prompt for the backend host if `--loki` is omitted. There is no teardown script — use `docker compose -f <path> down` directly.

To deploy Prometheus standalone: `docker compose -f prometheus/docker-compose.yaml up -d` (no script exists).

## Grafana defaults

Admin login is `admin` / `Grafana-123` (set in the Compose env). The dashboard JSON for the 157.130 host lives at `grafana/dashboard/157.130.json` and is not auto-provisioned — import it manually in the UI, or wire up `grafana/provisioning/` (the path is mounted but currently empty).

## Linting

`.trunk/trunk.yaml` configures `trunk` with yamllint, markdownlint, shellcheck, and others. Run `trunk check` if available; configs live in `.trunk/configs/`.
