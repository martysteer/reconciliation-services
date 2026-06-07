# Modular Reconciliation Service Container — Design Spec

**Date:** 2026-06-07
**Status:** Draft

## Goal

Combine existing Python-based reconciliation services into a single monorepo with composable Docker deployment. Each service runs as an independent container. Users pick which services to include via compose file selection. Deployable on Raspberry Pi 5 (8GB) or cloud infrastructure.

## Scope

### In Scope

| Service | Source Repo | Framework | Domain |
|---------|------------|-----------|--------|
| FAST | fast-reconciliation | Datasette + SQLite | OCLC FAST subject headings |
| GeoNames | geonames-reconciliation | Datasette + SQLite | GeoNames geographic features |
| ISO-lang | isolang-reconciliation | Datasette + SQLite | ISO 639 language codes |

All three implement the W3C Reconciliation Service API v0.2 using the same stack: Python 3.12, Datasette, datasette-reconcile plugin, SQLite with FTS5 full-text search.

### Out of Scope (Deferred)

- **VIAF reconciliation** — online/live category (queries external API). Different architectural pattern. Add after core is proven.
- **model-reconciler / granite-reconcile** — LLM-based services. Different infrastructure needs. model-reconciler kept as reference for architectural patterns only.
- **Clojure services** (reconcile-csv, reconcile-filesystem, reconcile-oaipmh, reconcile-skos) — different runtime. May be ported to Python later.
- **transation-reconcile** — empty/not started.
- **Gateway/proxy** — no reverse proxy. Each service exposes its own port directly.
- **CI/CD** — no automated pipeline prescribed. Manual build and deploy for now.

## Architecture

### Approach: Flat Monorepo

Each service is self-contained and independently buildable. No shared code, no abstractions. Compose files orchestrate which services run together.

```
reconciliation-services/
├── services/
│   ├── fast/
│   │   ├── Dockerfile
│   │   ├── Makefile
│   │   ├── fast.metadata.json
│   │   ├── xslt/
│   │   └── ...
│   ├── geonames/
│   │   ├── Dockerfile
│   │   ├── Makefile
│   │   ├── geonames.metadata.json
│   │   └── ...
│   └── isolang/
│       ├── Dockerfile          # new
│       ├── Makefile
│       ├── build_db.py
│       ├── iso639.metadata.json
│       └── ...
├── compose/
│   ├── fast.yml
│   ├── geonames.yml
│   └── isolang.yml
├── .env.example
├── Makefile
└── README.md
```

### Design Principles

- **Compose together, keep isolated.** Services share nothing. Each can be built, run, and debugged independently.
- **No premature abstraction.** Duplication across Dockerfiles is acceptable at 3 services. Refactor later if the service count grows.
- **Minimal changes to existing services.** Copy in, make it work in the new structure. No code changes, no interface normalization.

## Compose Files

Each compose file defines exactly one service. Users combine them with `-f` flags.

### compose/fast.yml

```yaml
services:
  fast:
    build: ../services/fast
    ports:
      - "${FAST_PORT:-8001}:8001"
    volumes:
      - fast-data:/app/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  fast-data:
```

### compose/geonames.yml

```yaml
services:
  geonames:
    build: ../services/geonames
    ports:
      - "${GEONAMES_PORT:-8002}:8001"
    volumes:
      - geonames-data:/app/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  geonames-data:
```

### compose/isolang.yml

```yaml
services:
  isolang:
    build: ../services/isolang
    ports:
      - "${ISOLANG_PORT:-8003}:8001"
    volumes:
      - isolang-data:/app/data
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8001"]
      interval: 30s
      timeout: 5s
      retries: 3

volumes:
  isolang-data:
```

### Port Allocation

| Service | Default Host Port | Container Port |
|---------|------------------|----------------|
| FAST | 8001 | 8001 |
| GeoNames | 8002 | 8001 |
| ISO-lang | 8003 | 8001 |

All services listen on 8001 internally. Host ports are configurable via `.env`.

### .env.example

```
FAST_PORT=8001
GEONAMES_PORT=8002
ISOLANG_PORT=8003
```

## Top-Level Makefile

Convenience wrapper around `docker compose`. No custom logic.

```makefile
SERVICES ?= fast geonames isolang

COMPOSE_FILES := $(foreach s,$(SERVICES),-f compose/$(s).yml)

up:
	docker compose $(COMPOSE_FILES) up -d

down:
	docker compose $(COMPOSE_FILES) down

build:
	docker compose $(COMPOSE_FILES) build

logs:
	docker compose $(COMPOSE_FILES) logs -f

status:
	docker compose $(COMPOSE_FILES) ps
```

### Usage

```bash
make up                              # all three services
make up SERVICES="fast geonames"     # select two
make build SERVICES="isolang"        # build one
make logs SERVICES="fast"            # tail logs for one
```

Each service also retains its own Makefile inside `services/<name>/` for standalone development.

## New Work: isolang Dockerfile

The only service without an existing Dockerfile. Based on the same Datasette pattern as GeoNames.

```dockerfile
FROM python:3.12-slim

WORKDIR /app

RUN pip install --no-cache-dir \
    datasette \
    datasette-reconcile \
    sqlite-utils \
    httpx

COPY . .

# Download source data and build SQLite database
RUN make build

EXPOSE 8001

CMD ["datasette", "serve", "--host", "0.0.0.0", "--port", "8001", \
     "--metadata", "iso639.metadata.json", "data/iso639.db"]
```

## Changes From Existing Services

### fast-reconciliation → services/fast/

- Copy as-is
- Remove its docker-compose.yml (replaced by compose/fast.yml)
- No code changes

### geonames-reconciliation → services/geonames/

- Copy as-is
- Remove its docker-compose.yml (replaced by compose/geonames.yml)
- No code changes

### isolang-reconciliation → services/isolang/

- Copy as-is
- Add new Dockerfile (above)
- Verify `make build` works inside Docker context (needs network access for data downloads)
- No code changes to build_db.py or metadata

## Build & Deploy

### Building (on capable machine)

```bash
git clone <repo> && cd reconciliation-services
make build                    # build all images
make build SERVICES="fast"    # build one
```

### Deploying to Pi 5

**Option A — Multi-arch build, push to registry:**
```bash
docker buildx build --platform linux/arm64 \
  -t registry/recon-fast:latest services/fast --push
```
On Pi: pull and run.

**Option B — Build locally, transfer:**
```bash
docker save recon-fast:latest | gzip > recon-fast.tar.gz
# scp to Pi, then:
docker load < recon-fast.tar.gz
```

### Estimated Image Sizes

| Service | Estimated Size | Reason |
|---------|---------------|--------|
| isolang | ~150MB | Small dataset |
| fast | ~2GB | 1.5GB+ FAST database baked in |
| geonames | ~3.5GB | 3GB GeoNames database baked in |

Large images are the trade-off for self-contained, zero-config runtime.

### Build-Time Constraints

- **FAST:** 30-60 min build (XSLT transformation). Requires Java/Saxon in build stage. Needs 12-16GB RAM for XSLT transform.
- **GeoNames:** ~10 min build. Downloads ~400MB zip.
- **ISO-lang:** Fast build. Small downloads from LOC and SIL.

All builds require internet access for data downloads.

## Service Endpoints

Once running, services are accessible at:

| Service | Reconciliation Endpoint |
|---------|------------------------|
| FAST | `http://localhost:8001/fast/FAST/-/reconcile` |
| GeoNames | `http://localhost:8002/geonames/geonames/-/reconcile` |
| ISO-lang | `http://localhost:8003/iso639/languages/-/reconcile` |

These URLs are configured directly in OpenRefine as reconciliation service endpoints.

## Future Expansion

When adding new services:

1. Create `services/<name>/` with Dockerfile and service code
2. Create `compose/<name>.yml`
3. Add port default to `.env.example`
4. Update README

For VIAF (next likely addition): same compose pattern, but flagged as "online/live" category in docs since it queries an external API rather than serving local data.

For Clojure services: either port to Python (preferred) or containerize with pre-built uberjars.
