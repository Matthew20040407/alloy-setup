# Alloy Setup

Log collection stack using **Grafana Alloy**, **Loki**, **Prometheus**, and **Grafana**.

## Architecture

```text
Host logs / Docker logs / metrics
        │
        ▼
   Grafana Alloy   (collector)   :12345
        │
        ▼
 Loki :3100 + Prometheus :9090   (backend, one box)
        │
        ▼
    Grafana        (dashboard)   :3000
```

The backend (Loki + Prometheus + Grafana) runs on one machine via
`full_obs_stack.yaml`. Every other machine runs only an Alloy collector that
pushes to that backend's IP.

## Deploy

### Backend (Loki + Prometheus + Grafana)

On the box that will hold the dashboard:

```bash
./deploy-full.sh
```

Brings up `full_obs_stack.yaml` — all three services on a shared Docker
network. This is the only script for the backend; there is no teardown
script (`docker compose -f full_obs_stack.yaml down`).

### Alloy (generic)

On any other machine, with no host-specific log pipelines needed:

```bash
./deploy-alloy.sh --loki 192.168.157.169
```

`--loki` takes the backend host's IP (or hostname) and derives both the
Loki push URL and the Prometheus remote-write URL from it — the two always
live on the same box. Omit the flag and you'll be prompted, with the
current default backend offered.

### Alloy (host-specific config)

Some hosts have their own `alloy/<server_ip>/` bundle with tailored
`loki.process` pipelines and/or extra exporters (e.g. `157.127` runs a
DCGM sidecar for GPU metrics). Each bundle is self-contained — its own
`config.alloy`, `docker-compose.yaml`, and `deploy.sh`:

```bash
cd alloy/157.127
./deploy.sh --loki 192.168.157.169
```

Same `--loki` flag and prompt-if-omitted behavior as the generic script.

Every deploy script prompts `[y/N]` before running `docker compose up -d`.

## What Alloy collects

- **System logs** — `/var/log/*.log`
- **Docker container logs** — via Docker socket, labeled with `container` and `image`
- **Container metrics** — cAdvisor
- **Host metrics** (some hosts) — `prometheus.exporter.unix`
- **GPU metrics** (157.127 only) — DCGM exporter sidecar
- Host-specific bundles additionally parse structured fields out of known
  services (SIP server, RAG app, Redis, Qdrant, Telegram bot on `157.130`)

## Configuration

| File                                  | Purpose                                              |
| -------------------------------------- | ----------------------------------------------------- |
| `alloy/config.alloy`                   | Generic Alloy pipeline — sources, relabeling          |
| `alloy/<server_ip>/config.alloy`       | Host-specific pipeline, drifts independently per host |
| `loki/loki-config.yaml`                | Loki storage and retention (per-service deploy only)  |
| `prometheus/prometheus.yaml`           | Prometheus scrape/global config (per-service deploy only) |
| `full_obs_stack.yaml`                  | All-in-one backend Compose (Loki + Prometheus + Grafana) |
| `scripts/lib/deploy-common.sh`         | Shared `--loki` flag parsing used by every deploy.sh   |

### Backend endpoint

Alloy configs read the backend URL from the `LOKI_URL` / `PROMETHEUS_URL`
environment variables via `sys.env(...)`, set by the deploy scripts from
`--loki`. If those env vars are unset (e.g. running `docker compose up -d`
directly instead of through a deploy script), each config falls back to the
current default backend `192.168.157.169` via `coalesce(...)`.

## Grafana login

| Field    | Value                   |
| -------- | ----------------------- |
| URL      | `http://localhost:3000` |
| Username | `admin`                 |
| Password | `Grafana-123`           |
