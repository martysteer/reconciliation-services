# Modular Reconciliation Service Container — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Combine FAST, GeoNames, and ISO-lang reconciliation services into a flat monorepo with composable Docker deployment.

**Architecture:** Each service copied into `services/<name>/` as-is. Per-service compose files in `compose/`. Top-level Makefile wraps `docker compose` with service selection via `SERVICES` variable. No shared code between services.

**Tech Stack:** Python 3.12, Datasette, datasette-reconcile, SQLite + FTS5, Docker, docker-compose, Make

**Spec:** `docs/2026-06-07-modular-reconciliation-container-design.md`

---

## File Structure

```
reconciliation-services/          # new monorepo root (this directory)
├── services/
│   ├── fast/                     # copied from fast-reconciliation/
│   │   ├── .gitignore
│   │   ├── Dockerfile
│   │   ├── Makefile
│   │   ├── fast.metadata.json
│   │   ├── README.md
│   │   └── xslt/
│   │       ├── fast2skos.xsl
│   │       └── skos2csv-reconcile.xsl
│   ├── geonames/                 # copied from geonames-reconciliation/
│   │   ├── .dockerignore
│   │   ├── .gitignore
│   │   ├── Dockerfile
│   │   ├── Makefile
│   │   ├── geonames.metadata.json
│   │   ├── README.md
│   │   └── test-data.csv
│   └── isolang/                  # copied from isolang-reconciliation/
│       ├── .gitignore
│       ├── Dockerfile            # NEW — to be created
│       ├── .dockerignore         # NEW — to be created
│       ├── Makefile
│       ├── build_db.py
│       ├── iso639.metadata.json
│       └── README.md
├── compose/
│   ├── fast.yml                  # NEW
│   ├── geonames.yml              # NEW
│   └── isolang.yml               # NEW
├── .env.example                  # NEW
├── .gitignore                    # NEW
├── Makefile                      # NEW — top-level wrapper
├── README.md                     # NEW
└── docs/
    ├── 2026-06-07-modular-reconciliation-container-design.md  # existing spec
    └── 2026-06-07-modular-reconciliation-container-plan.md    # this plan
```

**Files created:** 9 new files (3 compose YAMLs, top-level Makefile, .env.example, .gitignore, README, isolang Dockerfile, isolang .dockerignore)
**Files copied:** All source files from 3 existing service directories (excluding data/, .venv/, docker-compose.yml)
**Files modified:** isolang Makefile (minor — add Docker-compatible `serve` host binding)

---

## Task 1: Initialize Monorepo

**Files:**
- Create: `services/` directory
- Create: `compose/` directory
- Create: `.gitignore`

- [ ] **Step 1: Create directory structure**

```bash
cd "/Users/marty/Devel/Reconciliation services"
mkdir -p services compose
```

- [ ] **Step 2: Create root .gitignore**

Create `.gitignore`:

```gitignore
# Python
__pycache__/
*.py[cod]
.venv/

# Data (built at docker build time)
*.db
*.db-shm
*.db-wal

# Environment (may contain custom config)
.env

# OS
.DS_Store

# IDE
.idea/
.vscode/
```

- [ ] **Step 3: Initialize git repo**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git init
git add .gitignore docs/
git commit -m "init: monorepo with design spec and plan"
```

---

## Task 2: Copy FAST Service

**Files:**
- Create: `services/fast/` (all files from `fast-reconciliation/`)

- [ ] **Step 1: Copy service files (excluding data, venv, docker-compose)**

```bash
cd "/Users/marty/Devel/Reconciliation services"
mkdir -p services/fast
cp fast-reconciliation/.gitignore services/fast/
cp fast-reconciliation/Dockerfile services/fast/
cp fast-reconciliation/Makefile services/fast/
cp fast-reconciliation/fast.metadata.json services/fast/
cp fast-reconciliation/README.md services/fast/
cp -r fast-reconciliation/xslt services/fast/
```

Do NOT copy: `docker-compose.yml` (replaced by `compose/fast.yml`), `data/` directory (built at Docker build time).

- [ ] **Step 2: Verify Dockerfile builds independently**

```bash
cd "/Users/marty/Devel/Reconciliation services/services/fast"
docker build --no-cache -t recon-fast . 2>&1 | tail -5
```

Expected: Build completes (will take 30-60 min due to XSLT transform and data download). If testing locally, a quick syntax check is sufficient:

```bash
docker build --check . 2>&1 || echo "Docker BuildKit check not available, skip"
```

- [ ] **Step 3: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add services/fast/
git commit -m "add: FAST reconciliation service

Copied from fast-reconciliation/. Multi-stage Dockerfile
(Java/Saxon for XSLT, Python/Datasette for runtime).
docker-compose.yml excluded — replaced by compose/fast.yml."
```

---

## Task 3: Copy GeoNames Service

**Files:**
- Create: `services/geonames/` (all files from `geonames-reconciliation/`)

- [ ] **Step 1: Copy service files (excluding data, venv, docker-compose, downloaded files)**

```bash
cd "/Users/marty/Devel/Reconciliation services"
mkdir -p services/geonames
cp geonames-reconciliation/.dockerignore services/geonames/
cp geonames-reconciliation/.gitignore services/geonames/
cp geonames-reconciliation/Dockerfile services/geonames/
cp geonames-reconciliation/Makefile services/geonames/
cp geonames-reconciliation/geonames.metadata.json services/geonames/
cp geonames-reconciliation/README.md services/geonames/
cp geonames-reconciliation/test-data.csv services/geonames/
```

Do NOT copy: `docker-compose.yml`, `allCountries.zip`, `allCountries.txt`, `featureCodes_en.txt`, `geonames.db`, `.python-version`.

- [ ] **Step 2: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add services/geonames/
git commit -m "add: GeoNames reconciliation service

Copied from geonames-reconciliation/. Single-stage Dockerfile.
docker-compose.yml excluded — replaced by compose/geonames.yml."
```

---

## Task 4: Copy ISO-lang Service and Create Dockerfile

**Files:**
- Create: `services/isolang/` (files from `isolang-reconciliation/`)
- Create: `services/isolang/Dockerfile` (new)
- Create: `services/isolang/.dockerignore` (new)
- Modify: `services/isolang/Makefile` (bind host to 0.0.0.0 for Docker)

- [ ] **Step 1: Copy service files (excluding data, venv)**

```bash
cd "/Users/marty/Devel/Reconciliation services"
mkdir -p services/isolang
cp isolang-reconciliation/.gitignore services/isolang/
cp isolang-reconciliation/Makefile services/isolang/
cp isolang-reconciliation/build_db.py services/isolang/
cp isolang-reconciliation/iso639.metadata.json services/isolang/
cp isolang-reconciliation/README.md services/isolang/
```

- [ ] **Step 2: Create Dockerfile**

Create `services/isolang/Dockerfile`:

```dockerfile
# ISO 639 Language Code Reconciliation Service
#
# Build:  docker build -t recon-isolang .
# Run:    docker run -p 8003:8001 recon-isolang

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="ISO 639 Language Code Reconciliation Service for OpenRefine"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    datasette \
    datasette-reconcile \
    sqlite-utils

# Copy all service files
COPY . .

# Create data directory and build database
RUN mkdir -p data && make build

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

CMD ["make", "serve", "PUBLIC=1"]
```

- [ ] **Step 3: Create .dockerignore**

Create `services/isolang/.dockerignore`:

```dockerignore
data/
.venv/
__pycache__/
*.pyc
*.py[cod]
.git/
.gitignore
.DS_Store
```

- [ ] **Step 4: Modify Makefile serve target for Docker compatibility**

The existing `serve` target binds to `127.0.0.1`, which won't work inside a container. Add a `PUBLIC` variable to match the GeoNames pattern.

In `services/isolang/Makefile`, change the serve target's datasette command from:

```makefile
	@$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host 127.0.0.1
```

to:

```makefile
	@$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host $(if $(PUBLIC),0.0.0.0,127.0.0.1)
```

This allows `make serve PUBLIC=1` to bind to all interfaces (for Docker), while `make serve` still binds to localhost (for local dev).

- [ ] **Step 5: Handle venv in Docker context**

The Makefile creates a venv and uses `$(VENV_DIR)/bin/python3` etc. Inside Docker, packages are installed globally by `pip install` in the Dockerfile. The Makefile's venv target will still run inside Docker during `make build`, which is harmless (it creates a venv and installs packages — redundant but functional).

No change needed. The Makefile works in both contexts without modification beyond the host binding.

- [ ] **Step 6: Test Dockerfile builds**

```bash
cd "/Users/marty/Devel/Reconciliation services/services/isolang"
docker build -t recon-isolang .
```

Expected: Build succeeds. Downloads ~1MB of ISO 639 data, builds SQLite database. Should complete in under 2 minutes.

- [ ] **Step 7: Test container runs**

```bash
docker run --rm -d -p 8003:8001 --name isolang-test recon-isolang
sleep 5
curl -s http://localhost:8003/iso639/languages/-/reconcile | head -c 200
docker stop isolang-test
```

Expected: JSON response with reconciliation service manifest (name, identifierSpace, etc.).

- [ ] **Step 8: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add services/isolang/
git commit -m "add: ISO-lang reconciliation service with new Dockerfile

Copied from isolang-reconciliation/. New Dockerfile and .dockerignore
created (service had no Docker support). Makefile serve target updated
to support PUBLIC=1 for container host binding."
```

---

## Task 5: Create Compose Files

**Files:**
- Create: `compose/fast.yml`
- Create: `compose/geonames.yml`
- Create: `compose/isolang.yml`

- [ ] **Step 1: Create compose/fast.yml**

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
    restart: unless-stopped

volumes:
  fast-data:
```

- [ ] **Step 2: Create compose/geonames.yml**

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
    restart: unless-stopped

volumes:
  geonames-data:
```

- [ ] **Step 3: Create compose/isolang.yml**

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
    restart: unless-stopped

volumes:
  isolang-data:
```

- [ ] **Step 4: Verify compose file syntax**

```bash
cd "/Users/marty/Devel/Reconciliation services"
docker compose -f compose/isolang.yml config --quiet && echo "isolang: OK"
docker compose -f compose/geonames.yml config --quiet && echo "geonames: OK"
docker compose -f compose/fast.yml config --quiet && echo "fast: OK"
```

Expected: All three print "OK" with no errors.

- [ ] **Step 5: Verify multi-file compose works**

```bash
cd "/Users/marty/Devel/Reconciliation services"
docker compose -f compose/fast.yml -f compose/geonames.yml -f compose/isolang.yml config --quiet && echo "combined: OK"
```

Expected: "combined: OK" — no port conflicts, no volume name conflicts.

- [ ] **Step 6: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add compose/
git commit -m "add: per-service compose files

Pick-and-choose deployment via docker compose -f flags.
Each file defines one service with configurable host port
and named data volume."
```

---

## Task 6: Create Top-Level Makefile and .env.example

**Files:**
- Create: `Makefile`
- Create: `.env.example`

- [ ] **Step 1: Create top-level Makefile**

Create `Makefile` at repo root:

```makefile
# Modular Reconciliation Services
#
# Usage:
#   make up                            Start all services
#   make up SERVICES="fast geonames"   Start selected services
#   make build                         Build all images
#   make down                          Stop all services
#   make logs                          Tail logs
#   make status                        Show running services

SERVICES ?= fast geonames isolang

COMPOSE_FILES := $(foreach s,$(SERVICES),-f compose/$(s).yml)

.PHONY: up down build logs status

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

- [ ] **Step 2: Create .env.example**

Create `.env.example`:

```
# Host ports for reconciliation services
# Copy to .env and modify as needed
FAST_PORT=8001
GEONAMES_PORT=8002
ISOLANG_PORT=8003
```

- [ ] **Step 3: Test Makefile with isolang (fastest to build)**

```bash
cd "/Users/marty/Devel/Reconciliation services"
make build SERVICES="isolang"
make up SERVICES="isolang"
make status SERVICES="isolang"
```

Expected: isolang container builds, starts, and shows as running/healthy.

- [ ] **Step 4: Verify service responds**

```bash
curl -s http://localhost:8003/iso639/languages/-/reconcile | python3 -m json.tool | head -20
```

Expected: JSON reconciliation manifest with service name and entity types.

- [ ] **Step 5: Tear down**

```bash
cd "/Users/marty/Devel/Reconciliation services"
make down SERVICES="isolang"
```

- [ ] **Step 6: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add Makefile .env.example
git commit -m "add: top-level Makefile and .env.example

Makefile wraps docker compose with SERVICES variable for
pick-and-choose deployment. .env.example documents port defaults."
```

---

## Task 7: Create README

**Files:**
- Create: `README.md`

- [ ] **Step 1: Create README.md**

Create `README.md` at repo root:

```markdown
# Reconciliation Services

Modular W3C Reconciliation Service API endpoints for OpenRefine. Each service runs as an independent Docker container. Pick which services to deploy via compose file selection.

## Services

| Service | Domain | Default Port | Endpoint |
|---------|--------|-------------|----------|
| fast | OCLC FAST subject headings | 8001 | `/fast/FAST/-/reconcile` |
| geonames | GeoNames geographic features | 8002 | `/geonames/geonames/-/reconcile` |
| isolang | ISO 639 language codes | 8003 | `/iso639/languages/-/reconcile` |

## Quick Start

```bash
# Build and start all services
make build
make up

# Or select specific services
make up SERVICES="fast geonames"
```

## Usage

```bash
make build                           # Build all images
make build SERVICES="isolang"        # Build one image
make up                              # Start all services
make up SERVICES="fast geonames"     # Start selected services
make down                            # Stop all services
make logs                            # Tail all logs
make logs SERVICES="fast"            # Tail one service's logs
make status                          # Show running services
```

## Configuration

Copy `.env.example` to `.env` to customize ports:

```bash
cp .env.example .env
```

Default ports: FAST=8001, GeoNames=8002, ISO-lang=8003.

## Build Requirements

Images are built on a capable machine (12-16GB RAM recommended for FAST service XSLT transform). Runtime target is Raspberry Pi 5 (8GB) or cloud.

| Service | Build Time | Image Size | Data Source |
|---------|-----------|------------|-------------|
| isolang | < 2 min | ~150MB | LOC, SIL International |
| geonames | ~10 min | ~3.5GB | GeoNames.org |
| fast | 30-60 min | ~2GB | OCLC FAST |

## Adding a Service

1. Create `services/<name>/` with Dockerfile and service code
2. Create `compose/<name>.yml`
3. Add port default to `.env.example`
4. Update this README
```

- [ ] **Step 2: Commit**

```bash
cd "/Users/marty/Devel/Reconciliation services"
git add README.md
git commit -m "add: README with usage, configuration, and service docs"
```

---

## Task 8: End-to-End Verification

No new files. Verify the full system works.

- [ ] **Step 1: Build isolang (fastest, proves the pattern)**

```bash
cd "/Users/marty/Devel/Reconciliation services"
make build SERVICES="isolang"
```

Expected: Docker image builds successfully.

- [ ] **Step 2: Start isolang and verify endpoint**

```bash
make up SERVICES="isolang"
sleep 10
curl -s http://localhost:8003/iso639/languages/-/reconcile | python3 -m json.tool | head -10
```

Expected: JSON manifest with service metadata.

- [ ] **Step 3: Test a reconciliation query**

```bash
curl -s -X POST http://localhost:8003/iso639/languages/-/reconcile \
  -d 'queries={"q0":{"query":"english"}}' | python3 -m json.tool
```

Expected: JSON response with matching language records (English, Old English, Middle English, etc.).

- [ ] **Step 4: Test multi-service compose (isolang + one other)**

If GeoNames image is available (or after building it):

```bash
make build SERVICES="isolang geonames"
make up SERVICES="isolang geonames"
make status SERVICES="isolang geonames"
curl -s http://localhost:8003/ | head -c 100
curl -s http://localhost:8002/ | head -c 100
make down SERVICES="isolang geonames"
```

Expected: Both services start on their respective ports, respond independently, and stop cleanly.

- [ ] **Step 5: Verify .env port override works**

```bash
cd "/Users/marty/Devel/Reconciliation services"
echo "ISOLANG_PORT=9999" > .env
make up SERVICES="isolang"
curl -s http://localhost:9999/iso639/languages/-/reconcile | head -c 100
make down SERVICES="isolang"
rm .env
```

Expected: Service responds on port 9999 instead of default 8003.

- [ ] **Step 6: Clean up**

```bash
cd "/Users/marty/Devel/Reconciliation services"
make down
```

---

## Summary

| Task | What | New Files |
|------|------|-----------|
| 1 | Init monorepo, dirs, git | `.gitignore` |
| 2 | Copy FAST service | `services/fast/*` |
| 3 | Copy GeoNames service | `services/geonames/*` |
| 4 | Copy ISO-lang + create Dockerfile | `services/isolang/*`, new Dockerfile + .dockerignore |
| 5 | Create compose files | `compose/fast.yml`, `compose/geonames.yml`, `compose/isolang.yml` |
| 6 | Top-level Makefile + .env | `Makefile`, `.env.example` |
| 7 | README | `README.md` |
| 8 | End-to-end verification | (no new files) |
