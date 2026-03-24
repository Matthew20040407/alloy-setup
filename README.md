# Alloy Setup

Log collection stack using **Grafana Alloy**, **Loki**, and **Grafana**.

## Architecture

```
Host logs / Docker logs
        │
        ▼
   Grafana Alloy   (collector)   :12345
        │
        ▼
      Loki         (log store)   :3100
        │
        ▼
    Grafana        (dashboard)   :3000
```

## Services

| Service | Image | Port |
|---------|-------|------|
| Alloy | `grafana/alloy:latest` | `12345` (debug UI) |
| Loki | `grafana/loki` | `3100` |
| Grafana | `grafana/grafana:latest` | `3000` |

## What Alloy collects

- **System logs** — `/var/log/*.log`
- **Docker container logs** — via Docker socket, labeled with `container` and `image`
- **App logs** *(optional, commented out)* — `/app/logs/*.log` with JSON level extraction

## Deploy

### Grafana + Loki

```bash
./deploy-grafana-loki.sh
```

### Alloy

```bash
./deploy-alloy.sh
```

Each script prompts for confirmation before running `docker compose up -d`.

## Configuration

| File | Purpose |
|------|---------|
| `alloy/config.alloy` | Alloy pipeline — sources, relabeling, Loki endpoint |
| `loki/loki-config.yaml` | Loki storage and retention settings |
| `grafana/docker-compose.yaml` | Grafana env vars and volume mounts |

### Loki endpoint

Set in [alloy/config.alloy](alloy/config.alloy) at the `loki.write` block:

```alloy
loki.write "default" {
  endpoint {
    url = "http://<LOKI_IP>:3100/loki/api/v1/push"
  }
}
```

Update `<LOKI_IP>` to match your Loki host.

## Grafana login

| Field | Value |
|-------|-------|
| URL | `http://localhost:3000` |
| Username | `admin` |
| Password | `Grafana-123` |
