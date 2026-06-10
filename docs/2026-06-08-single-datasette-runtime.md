# Single Datasette Runtime Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace three per-service Datasette containers with one thin runtime container serving multiple SQLite database files from a bind-mounted `data/` directory, with per-dataset builder images that export `.db` artifacts.

**Architecture:** Each `services/<name>/Dockerfile` becomes a builder-only image with a `FROM scratch AS export` final stage; `docker build --output type=local,dest=data` exports the built `.db` file to the host `data/` directory (BuildKit layer caching keeps re-exports fast). A new `services/runtime/` image contains only Datasette + datasette-reconcile + a merged `metadata.json` (generated at image build time from all `services/*/*.metadata.json`), and serves every `/data/*.db` it finds in **immutable mode** (`-i`) on one port. Datasette namespaces each database file by name, so all existing reconcile endpoints keep their paths — only the port unifies.

**Tech Stack:** Docker BuildKit (`--output type=local`), Docker Compose, Datasette 0.65.2 (`-i` immutable mode, config via `--metadata`), datasette-reconcile 0.6.3, SQLite/FTS5, GNU Make.

**Resulting endpoints (single port, default 8000):**

```
http://127.0.0.1:8000/fast/FAST/-/reconcile          (+ 9 per-facet tables)
http://127.0.0.1:8000/geonames/geonames/-/reconcile
http://127.0.0.1:8000/iso639/languages/-/reconcile
```

**Why immutable (`-i`) mode:** works on a read-only bind mount (no `-wal`/`-shm` files), enables Datasette performance optimisations, and is correct for databases that are only ever replaced wholesale.

**Why NOT one merged .db:** a single file would mean any dataset refresh rewrites ~5GB, write locks block all queries during rebuild, and per-dataset transfer granularity is lost. Multiple `.db` files give the same single-container result without those costs.

**Adding a future dataset:** create `services/<name>/` with a builder Dockerfile (export stage emitting `<name>.db`) and a `<name>.metadata.json` with a `databases` section; run `make data SERVICES="<name>"`; rebuild the runtime image (`make build` — it globs all `services/*/*.metadata.json`); restart. No new port, no new compose file.

**Key constraints learned from the current codebase:**

- `services/isolang/` builds a database named `iso639.db` (NOT `isolang.db`) — the database URL namespace is `/iso639/`.
- The FAST builder needs ~12GB Docker VM RAM and the `FASTAll.marcxml.zip` Cloudflare workaround (optional `COPY ... FASTAll.marcxml.zi[p]` glob already in place). Full FAST verification is OPTIONAL in this plan; structural changes are verified by building the other two datasets.
- Compose resolves relative paths in compose files against the compose file's directory, and resolves the default `.env` against the directory of the first `-f` file — the root Makefile must keep passing `--env-file .env` explicitly.
- Each service's native mode (`make build && make serve` inside the service dir) must keep working unchanged — only Dockerfiles, compose, and the root Makefile change.

**Out of scope (YAGNI):** registries, multi-process supervisors, per-dataset healthchecks, metadata hot-reload, keeping the old per-service serving images.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `services/runtime/merge_metadata.py` | Create | Merge per-dataset metadata files into one Datasette metadata.json |
| `services/runtime/serve.sh` | Create | Entrypoint: glob `/data/*.db`, exec datasette with `-i` per file |
| `services/runtime/Dockerfile` | Create | Thin runtime image (context = repo root, so it can COPY all metadata files) |
| `services/isolang/Dockerfile` | Rewrite | Builder + export stages only (no serving) |
| `services/geonames/Dockerfile` | Rewrite | Builder + export stages only (no serving) |
| `services/fast/Dockerfile` | Modify | Replace runtime stage (lines 67–108) with export stage |
| `compose/recon.yml` | Create | Single runtime service, `../data:/data:ro` bind mount |
| `compose/fast.yml`, `compose/geonames.yml`, `compose/isolang.yml` | Delete | Superseded |
| `Makefile` (root) | Rewrite | `data` / `build` / `up` / `down` / `logs` / `status` / `save` / `clean` |
| `.env.example` | Rewrite | Single `RECON_PORT` |
| `.gitignore` (root) | Modify | Ignore `data/` |
| `README.md` (root) | Modify | New architecture, commands, transfer workflow |
| `services/{fast,geonames,isolang}/README.md` | Modify | Docker sections point at builder/export + shared runtime |

No automated test suite exists in this repo; verification is via exact shell commands with expected output (build → run → curl reconcile endpoint).

---

### Task 1: Metadata merge script

**Files:**
- Create: `services/runtime/merge_metadata.py`

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Merge per-dataset Datasette metadata files into one runtime metadata.json.

Usage: merge_metadata.py <file.metadata.json>... > metadata.json

Each services/<name>/<name>.metadata.json contributes its "databases"
section. Top-level license/source attribution in each file is pushed down
into its database entries so it survives the merge.
"""
import json
import sys
from pathlib import Path

ATTRIBUTION_KEYS = ("license", "license_url", "source", "source_url", "description")


def merge(paths):
    merged = {
        "title": "Reconciliation Services",
        "description": "W3C Reconciliation Service API endpoints for OpenRefine",
        "databases": {},
    }
    for path in sorted(paths):
        doc = json.loads(Path(path).read_text())
        for db_name, db in doc.get("databases", {}).items():
            if db_name in merged["databases"]:
                raise SystemExit(f"Duplicate database name '{db_name}' in {path}")
            for key in ATTRIBUTION_KEYS:
                if key in doc and key not in db:
                    db[key] = doc[key]
            merged["databases"][db_name] = db
    return merged


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    json.dump(merge(sys.argv[1:]), sys.stdout, indent=2)
    print()
```

- [ ] **Step 2: Run it against the three real metadata files and verify**

Run (from repo root):

```bash
python3 services/runtime/merge_metadata.py services/*/*.metadata.json | python3 -c "
import json, sys
m = json.load(sys.stdin)
assert sorted(m['databases']) == ['fast', 'geonames', 'iso639'], m['databases'].keys()
assert m['databases']['iso639']['license'] == 'Public Domain'
assert m['databases']['geonames']['license'] == 'CC BY 4.0'
assert m['databases']['fast']['tables']['FAST']['plugins']['datasette-reconcile']['id_field'] == 'id'
print('merge OK:', ', '.join(sorted(m['databases'])))
"
```

Expected output: `merge OK: fast, geonames, iso639`

(Note: `services/*/*.metadata.json` will also match nothing extra today; when `services/runtime/` exists it contains no `*.metadata.json`, so the glob stays correct.)

- [ ] **Step 3: Verify duplicate detection fails loudly**

Run:

```bash
python3 services/runtime/merge_metadata.py services/fast/fast.metadata.json services/fast/fast.metadata.json > /dev/null; echo "exit=$?"
```

Expected: stderr contains `Duplicate database name 'fast'` and output is `exit=1`.

- [ ] **Step 4: Commit**

```bash
git add services/runtime/merge_metadata.py
git commit -m "feat(runtime): add metadata merge script for multi-db datasette"
```

---

### Task 2: Convert isolang to builder + export

**Files:**
- Modify: `services/isolang/Dockerfile` (full rewrite)

- [ ] **Step 1: Rewrite `services/isolang/Dockerfile`**

```dockerfile
# ISO 639 dataset builder
#
# Builds iso639.db at IMAGE BUILD time. The final stage contains ONLY the
# database file -- export it to the host with BuildKit:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="isolang"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).

FROM python:3.12-slim AS builder

LABEL maintainer="SOAS Library Services"
LABEL description="ISO 639 dataset builder for the reconciliation runtime"

# System dependencies for the data pipeline
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir sqlite-utils==3.39

WORKDIR /app

# Selective copy keeps the build context explicit and preserves layer caching
COPY Makefile build_db.py ./

# Docker mode: use system Python, skip venv
ENV DOCKER=1

# Download source data and build the database at image build time
RUN make build

# =============================================================================
# Export stage: just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/iso639.db /
```

Note what was removed vs the current file: `datasette`/`datasette-reconcile` pip installs, `iso639.metadata.json` COPY, `useradd`/`USER` (builder never runs as a service; `--output` files land on the host owned by the invoking user), `EXPOSE`, `HEALTHCHECK`, `CMD`.

- [ ] **Step 2: Build and export, verify the database**

Run (from repo root):

```bash
mkdir -p data && docker build --target export --output type=local,dest=data services/isolang
```

Expected: build succeeds (< 2 min; `make build` output shows dataset downloads + FTS build).

Then:

```bash
sqlite3 data/iso639.db "SELECT COUNT(*) FROM languages; SELECT name FROM languages WHERE id='cym';"
```

Expected: a count around `8047`, and `Welsh`.

- [ ] **Step 3: Commit**

```bash
git add services/isolang/Dockerfile
git commit -m "refactor(isolang): convert image to builder + export stages"
```

---

### Task 3: Runtime image (serve.sh + Dockerfile)

**Files:**
- Create: `services/runtime/serve.sh`
- Create: `services/runtime/Dockerfile`

- [ ] **Step 1: Write `services/runtime/serve.sh`**

```sh
#!/bin/sh
# Serve every SQLite database found in /data.
#
# Immutable mode (-i): works on a read-only bind mount (no -wal/-shm files)
# and enables Datasette performance optimisations. Databases are replaced
# wholesale by rebuilding them on the host (`make data`), then restarting.
set -eu

set -- /data/*.db
if [ ! -e "$1" ]; then
    echo "ERROR: no .db files found in /data" >&2
    echo "Run 'make data' on the host to build dataset databases first." >&2
    exit 1
fi

args=""
for db in "$@"; do
    args="$args -i $db"
done

# $args is intentionally word-split: paths are /data/<name>.db (no spaces)
exec datasette serve $args \
    --metadata /app/metadata.json \
    --host 0.0.0.0 \
    --port 8001 \
    --setting sql_time_limit_ms 5000 \
    --setting max_returned_rows 1000
```

- [ ] **Step 2: Write `services/runtime/Dockerfile`**

IMPORTANT: this Dockerfile's build context is the **repo root** (so it can COPY every dataset's metadata file). It is built with `-f services/runtime/Dockerfile .` — never with `services/runtime` as the context.

```dockerfile
# Reconciliation runtime -- one Datasette serving every dataset in /data
#
# Build (context MUST be the repo root):
#   docker build -f services/runtime/Dockerfile -t recon-runtime .
# Run:
#   docker run -d -p 8000:8001 -v "$PWD/data:/data:ro" recon-runtime
#
# Data files are built separately (`make data`) and bind-mounted, so this
# image is small, architecture-cheap, and never needs rebuilding for a
# data refresh -- only when a dataset's metadata or the toolchain changes.

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="Reconciliation Services runtime (Datasette, multi-database)"

# curl needed for the healthcheck only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    datasette==0.65.2 \
    datasette-reconcile==0.6.3

# Non-root user
RUN useradd --create-home --uid 1000 app

WORKDIR /app

COPY services/runtime/serve.sh services/runtime/merge_metadata.py ./

# Every dataset contributes its metadata; the glob flattens
# services/<name>/<name>.metadata.json into ./metadata/
COPY services/*/*.metadata.json ./metadata/

RUN python merge_metadata.py metadata/*.metadata.json > metadata.json && \
    chmod +x serve.sh

USER app

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

CMD ["./serve.sh"]
```

(start-period=30s: with `-i`, Datasette counts table rows at startup; the 13M-row GeoNames FTS database takes a few seconds.)

- [ ] **Step 3: Build the runtime image**

Run (from repo root):

```bash
docker build -f services/runtime/Dockerfile -t recon-runtime .
```

Expected: success; the `RUN python merge_metadata.py ...` step completes without `Duplicate database name`.

- [ ] **Step 4: Smoke-test against data/iso639.db from Task 2**

Run:

```bash
docker run -d --rm --name recon-smoke -p 8000:8001 -v "$PWD/data:/data:ro" recon-runtime
sleep 3
curl -s "http://127.0.0.1:8000/iso639/languages/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22Welsh%22%7D%7D" | python3 -m json.tool
```

Expected: JSON containing `"id": "cym"` with `"score": 100`. Also verify the read-only mount caused no SQLite errors:

```bash
docker logs recon-smoke 2>&1 | tail -5
docker rm -f recon-smoke
```

Expected: normal uvicorn startup lines, no tracebacks.

- [ ] **Step 5: Verify empty-data failure message**

```bash
mkdir -p /tmp/empty-data
docker run --rm -v /tmp/empty-data:/data:ro recon-runtime; echo "exit=$?"
```

Expected: `ERROR: no .db files found in /data` and `exit=1`.

- [ ] **Step 6: Commit**

```bash
git add services/runtime/serve.sh services/runtime/Dockerfile
git commit -m "feat(runtime): add single datasette runtime image serving /data/*.db"
```

---

### Task 4: Compose, root Makefile, env, gitignore

**Files:**
- Create: `compose/recon.yml`
- Delete: `compose/fast.yml`, `compose/geonames.yml`, `compose/isolang.yml`
- Rewrite: `Makefile` (root)
- Rewrite: `.env.example`
- Modify: `.gitignore` (root)

- [ ] **Step 1: Write `compose/recon.yml`**

```yaml
services:
  recon:
    image: recon-runtime:latest
    build:
      context: ..
      dockerfile: services/runtime/Dockerfile
    ports:
      - "${RECON_PORT:-8000}:8001"
    volumes:
      - ../data:/data:ro
    restart: unless-stopped
```

(Relative paths resolve against the compose file's directory, so `../data` is the repo-root `data/`.)

- [ ] **Step 2: Delete the old compose files**

```bash
git rm compose/fast.yml compose/geonames.yml compose/isolang.yml
```

- [ ] **Step 3: Rewrite the root `Makefile`**

```makefile
# Reconciliation Services -- per-dataset builders + single Datasette runtime
#
# Usage:
#   make data                          Build all dataset .db files into data/
#   make data SERVICES="isolang"       Build selected datasets only
#   make build                         Build the runtime image
#   make up / down                     Start / stop the runtime
#   make logs / status                 Inspect the runtime
#   make save                          Export runtime image to dist/ for transfer
#   make clean                         Stop runtime and remove its image
#   make clean-data                    Remove built .db files
#
# Deploying elsewhere (e.g. Raspberry Pi): `make data && make build && make save`
# on a workstation, copy dist/recon-runtime.tar.gz + data/*.db to the target,
# `docker load`, then `make up` from a checkout of this repo. The .db files
# are architecture-independent; only the (small) runtime image is per-arch.

SERVICES ?= fast geonames isolang

# Compose resolves the default .env against the compose file directory,
# not the repo root, so pass it explicitly.
COMPOSE := docker compose -p recon $(if $(wildcard .env),--env-file .env) -f compose/recon.yml

.PHONY: data build up down logs status save clean clean-data

# Build each dataset's .db via its builder image and export it to data/.
# BuildKit caches the pipeline layers, so unchanged datasets re-export fast.
data:
	@mkdir -p data
	@for s in $(SERVICES); do \
		echo "==> Building dataset: $$s"; \
		docker build --target export --output type=local,dest=data "services/$$s" || exit 1; \
	done
	@ls -lh data/*.db

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

# Export the runtime image for offline transfer. Dataset .db files are
# transferred as plain files (scp data/*.db ...), not inside images.
save: SHELL := /bin/bash
save:
	@mkdir -p dist
	@set -euo pipefail; \
	echo "Saving recon-runtime:latest -> dist/recon-runtime.tar.gz"; \
	docker save recon-runtime:latest | gzip > dist/recon-runtime.tar.gz
	@ls -lh dist/

clean:
	$(COMPOSE) down --rmi all

clean-data:
	rm -f data/*.db
```

- [ ] **Step 4: Rewrite `.env.example`**

```bash
# Host port for the reconciliation runtime
# Copy to .env and modify as needed
RECON_PORT=8000
```

- [ ] **Step 5: Add `data/` to the root `.gitignore`**

Append this line to the existing root `.gitignore` (which currently contains `dist/`):

```
data/
```

- [ ] **Step 6: End-to-end verification with isolang data**

```bash
make build
make up
sleep 5
make status
curl -s "http://127.0.0.1:8000/iso639/languages/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22Welsh%22%7D%7D" | python3 -m json.tool
```

Expected: `make status` shows one `recon` service running (healthy after ~30s); curl returns `"id": "cym"`, `"score": 100`.

- [ ] **Step 7: Verify .env port override is honoured**

```bash
echo "RECON_PORT=9999" > .env
make down && make up
curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:9999/
make down
rm .env
make up
```

Expected: `200` from port 9999; service back on 8000 afterwards.

- [ ] **Step 8: Commit**

```bash
git add Makefile .env.example .gitignore compose/recon.yml
git commit -m "refactor: single-runtime compose + data/build split in root Makefile

Per-dataset builder images now export .db artifacts to data/; one
datasette container serves them all on a single port. Transfer to
Pi/server becomes: small runtime image + arch-independent .db files."
```

---

### Task 5: Convert geonames to builder + export

**Files:**
- Modify: `services/geonames/Dockerfile` (full rewrite)

- [ ] **Step 1: Rewrite `services/geonames/Dockerfile`**

```dockerfile
# GeoNames dataset builder
#
# Builds geonames.db at IMAGE BUILD time (~400MB download, ~10 min). The
# final stage contains ONLY the database file -- export it to the host:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="geonames"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).

FROM python:3.12-slim AS builder

LABEL maintainer="SOAS Library Services"
LABEL description="GeoNames dataset builder for the reconciliation runtime"

# System dependencies for the data pipeline
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir sqlite-utils==3.39

WORKDIR /app

COPY Makefile ./

# Environment: Docker mode + data paths
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV GEONAMES_ZIP=/app/data/allCountries.zip
ENV GEONAMES_TXT=/app/data/allCountries.txt
ENV FEATURE_CODES_TXT=/app/data/featureCodes_en.txt
ENV SQLITE_DB=/app/data/geonames.db

# Build the database at image build time; remove the ~2GB of intermediate
# download/extract files in the SAME layer so they never bloat the
# builder image / build cache.
RUN mkdir -p /app/data && \
    make build && \
    rm -f /app/data/allCountries.zip /app/data/allCountries.txt /app/data/featureCodes_en.txt

# =============================================================================
# Export stage: just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/geonames.db /
```

Removed vs current: `datasette`/`datasette-reconcile`/`httpx` pip installs (httpx is only used by the native `make test` target, never by `make build`), `geonames.metadata.json` COPY (only `make serve` reads it; the runtime image gets it from the host), `useradd`/`USER`, `EXPOSE`, `HEALTHCHECK`, `CMD`.

- [ ] **Step 2: Build and export (~12 min), verify**

```bash
make data SERVICES="geonames"
sqlite3 data/geonames.db "SELECT COUNT(*) FROM geonames;"
```

Expected: export succeeds; count is 13M+ (13,400,000-ish).

If `make build` inside the container fails with a missing-tool error, the dropped dependency was actually needed — add only that package back to the builder stage, not the whole previous set.

- [ ] **Step 3: Restart runtime and verify geonames endpoint appears (no image rebuild needed)**

```bash
make down && make up
sleep 10
curl -s "http://127.0.0.1:8000/geonames/geonames/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22London%22%7D%7D" | python3 -m json.tool | head -20
curl -s "http://127.0.0.1:8000/iso639/languages/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22Welsh%22%7D%7D" | python3 -c "import json,sys; print(json.load(sys.stdin)['q0']['result'][0]['id'])"
```

Expected: London result includes `"id": "2643743"` (or similar GeoNames id, score 100); second command prints `cym` — both datasets served by one container.

- [ ] **Step 4: Commit**

```bash
git add services/geonames/Dockerfile
git commit -m "refactor(geonames): convert image to builder + export stages"
```

---

### Task 6: Convert fast to builder + export

**Files:**
- Modify: `services/fast/Dockerfile`

- [ ] **Step 1: Update the header comment block (lines 1–15)**

Replace with:

```dockerfile
# FAST dataset builder
#
# Stage 1 (builder): Java/Saxon runs the full data pipeline at IMAGE BUILD
#                    time (MARC XML -> SKOS -> CSV -> SQLite). Needs 12-16GB
#                    RAM available to Docker (see README).
# Stage 2 (export):  contains ONLY fast.db -- export it to the host:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="fast"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).
#
# OCLC download may be blocked by Cloudflare. If so, download
# FASTAll.marcxml.zip manually and place it in this directory
# (services/fast/) before building -- it will be picked up automatically.
```

- [ ] **Step 2: Replace the entire runtime stage**

Delete everything from the `# Stage 2: Runtime` banner comment (current line 67) to the end of the file (the `FROM python:3.12-slim` stage with its LABEL/RUN/COPY/HEALTHCHECK/CMD), and replace with:

```dockerfile
# =============================================================================
# Stage 2: Export -- just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/fast.db /
```

Also remove the now-unneeded `fast.metadata.json` from the builder's COPY line (current line 50) — change:

```dockerfile
COPY Makefile fast.metadata.json FASTAll.marcxml.zi[p] ./
```

to:

```dockerfile
COPY Makefile FASTAll.marcxml.zi[p] ./
```

- [ ] **Step 3: Structural verification (full build NOT required)**

The full FAST pipeline needs the manually-downloaded zip and 30–60 min; do not block on it. Verify the Dockerfile parses and the early layers work by building only until the pipeline RUN would start, using a deliberate cache-only check:

```bash
docker build --target export services/fast 2>&1 | head -30 || true
```

Expected: build proceeds through the apt/Saxon/pip/COPY layers and fails (or starts downloading) only inside `make build` — i.e. the Cloudflare error from the Makefile, not a Dockerfile syntax/stage error. If `services/fast/FASTAll.marcxml.zip` is present on this machine, instead run the real thing:

```bash
make data SERVICES="fast"
sqlite3 data/fast.db "SELECT COUNT(*) FROM FAST;"
make down && make up
```

Expected: count ~2M; `/fast/FAST/-/reconcile` then responds on port 8000.

- [ ] **Step 4: Commit**

```bash
git add services/fast/Dockerfile
git commit -m "refactor(fast): replace runtime stage with export stage"
```

---

### Task 7: Documentation

**Files:**
- Modify: `README.md` (root)
- Modify: `services/fast/README.md`
- Modify: `services/geonames/README.md`
- Modify: `services/isolang/README.md`

- [ ] **Step 1: Rewrite the root `README.md` top sections**

Replace the intro + Services + Quick Start + Usage + Configuration sections with:

```markdown
# Reconciliation Services

W3C Reconciliation Service API endpoints for OpenRefine. One Datasette
container serves every dataset on a single port; each dataset is built by
its own builder image into an SQLite file in `data/`.

## Endpoints

All on one port (default 8000):

| Dataset | Endpoint |
|---------|----------|
| OCLC FAST subject headings | `/fast/FAST/-/reconcile` (+ per-facet tables, see services/fast) |
| GeoNames geographic features | `/geonames/geonames/-/reconcile` |
| ISO 639 language codes | `/iso639/languages/-/reconcile` |

## Quick Start

```bash
make data        # Build all dataset .db files into data/ (see notes below)
make build       # Build the runtime image
make up          # Start serving on http://127.0.0.1:8000/
```

## Usage

```bash
make data                            # Build all dataset databases
make data SERVICES="isolang"         # Build one dataset
make build                           # Build the runtime image
make up / make down                  # Start / stop
make logs / make status              # Inspect
make save                            # Export runtime image to dist/
make clean                           # Stop + remove runtime image
make clean-data                      # Remove built .db files
```

Refreshing one dataset: `make data SERVICES="geonames" && make down && make up`.
No image rebuild needed — the runtime picks up whatever `.db` files are in `data/`.

## Configuration

Copy `.env.example` to `.env` to customize the port (default `RECON_PORT=8000`).
```

- [ ] **Step 2: Update the root README "Build Requirements" notes**

Keep the FAST memory/Cloudflare notes (they still apply to `make data SERVICES="fast"`), update the table heading from image sizes to artifact sizes:

```markdown
| Dataset | Build Time | .db Size | Data Source |
|---------|-----------|----------|-------------|
| isolang | < 2 min | ~3MB | LOC, SIL International |
| geonames | ~12 min | ~3GB | GeoNames.org |
| fast | 30-60 min | ~1.5GB | OCLC FAST |

The runtime image itself is ~200MB and contains no data.
```

- [ ] **Step 3: Replace the root README "Upgrading" + "Deploying to a Pi" sections**

```markdown
## Upgrading from per-service containers

Earlier versions ran one container per dataset with data baked into each
image. Remove them before first `make up` with this version:

```bash
docker compose -p recon down
docker rmi recon-fast:latest recon-geonames:latest recon-isolang:latest
```

## Deploying to a Pi / Server (build on laptop, copy artifacts)

The Pi 5 (8GB) cannot build the FAST or GeoNames datasets itself. Build on
a workstation and copy across — no registry needed.

**1. On the laptop — build and export:**

```bash
make data && make build && make save
```

**2. Copy to the target machine:**

```bash
scp dist/recon-runtime.tar.gz data/*.db pi@raspberrypi.local:~
```

**3. On the Pi — load and run (from a checkout of this repo):**

```bash
docker load < ~/recon-runtime.tar.gz
mkdir -p data && mv ~/*.db data/
make up
```

The `.db` files are architecture-independent — only the small runtime image
is per-arch (an Apple Silicon Mac builds arm64 natively, correct for Pi 5;
for an amd64 server: `docker buildx build --platform linux/amd64 --load -t
recon-runtime:latest -f services/runtime/Dockerfile .`).

## Adding a Dataset

1. Create `services/<name>/` with a builder Dockerfile ending in:
   `FROM scratch AS export` + `COPY --from=builder /app/data/<name>.db /`
2. Add `services/<name>/<name>.metadata.json` with a `databases` section
   (see existing services; the runtime merges all of them at image build)
3. `make data SERVICES="<name>" && make build && make down && make up`
4. Update this README
```

- [ ] **Step 4: Update the three per-service READMEs**

In each, replace the "Option 1: Docker" quick-start block and the Docker column of the Commands table. The pattern for all three (shown for isolang; adapt names/times for the others):

```markdown
### Option 1: Docker

This directory builds the dataset (`iso639.db`); serving is done by the
shared runtime container (see repo root README).

```bash
# From the repo root:
make data SERVICES="isolang"    # build data/iso639.db (< 2 min)
make build && make up           # build + start the shared runtime

# Or standalone from this directory (writes ../../data/iso639.db):
docker build --target export --output type=local,dest=../../data .
```

Endpoint: `http://127.0.0.1:8000/iso639/languages/-/reconcile`
```

Specifics per service:
- **fast**: keep the Cloudflare table but the native row stays `services/fast/data/FASTAll.marcxml.zip` and Docker row stays `services/fast/FASTAll.marcxml.zip`; change every endpoint URL port from `8001` to `8000` (including the nine per-facet endpoint URLs); Commands table Docker column becomes `make data SERVICES="fast"` / `make build && make up` / `make down` / re-run `make data` (rebuild) / `make clean && make clean-data`; keep the 12GB RAM note.
- **geonames**: endpoint port `8002` → `8000`; same Commands-table treatment; note "the builder image keeps intermediate-free layers; the runtime container has no make".
- **isolang**: endpoint port `8003` → `8000`; same Commands-table treatment; Files tree gains no entries (Dockerfile already listed).

Native sections (`make build && make serve` on port 8001 inside each service dir) stay untouched in all three.

- [ ] **Step 5: Proofread rendered output**

```bash
grep -rn "8001\|8002\|8003" README.md services/*/README.md
```

Expected: remaining hits only in native-mode sections (per-service `make serve` really does listen on 8001) — no Docker-mode references to old ports.

- [ ] **Step 6: Commit**

```bash
git add README.md services/fast/README.md services/geonames/README.md services/isolang/README.md
git commit -m "docs: document single-runtime architecture and artifact transfer"
```

---

### Task 8: Final verification + old-image cleanup

- [ ] **Step 1: Full cold-path check**

```bash
make down
make status                 # expect: no recon services running
make up
sleep 10
docker ps --filter name=recon --format '{{.Names}} {{.Status}}'
```

Expected: one container, `Up ... (healthy)` after the 30s start period.

- [ ] **Step 2: Verify all built datasets respond**

```bash
for path in iso639/languages geonames/geonames; do \
  curl -s -o /dev/null -w "$path %{http_code}\n" "http://127.0.0.1:8000/$path/-/reconcile"; \
done
```

Expected: `200` for each dataset whose `.db` exists in `data/` (fast included if it was built in Task 6). A GET on a reconcile endpoint returns the service manifest JSON with `200`.

- [ ] **Step 3: Remove superseded images (frees ~7GB)**

```bash
docker rmi recon-fast:latest recon-geonames:latest recon-isolang:latest 2>/dev/null; docker image ls | head
```

Expected: old fat images gone (ignore "No such image" if already absent); `recon-runtime` remains.

- [ ] **Step 4: Working tree clean check**

```bash
git status
```

Expected: clean (everything committed in Tasks 1–7).
