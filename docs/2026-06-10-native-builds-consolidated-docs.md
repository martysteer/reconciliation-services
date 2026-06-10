# Native Builds + Consolidated Docs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make native `make` the only data-build pipeline (delete the three builder Dockerfiles), and consolidate all user documentation into the root README with per-service READMEs reduced to minimal stubs.

**Architecture:** Refactor A+B from the 2026-06-08 single-runtime design. The root Makefile `data` target switches from `docker build --target export` to driving each service's native `make build` and copying the resulting `.db` into `data/` ("copy after build" — per-service Makefiles keep building into their own directories, untouched paths). The only remaining Docker artifacts are the thin runtime (`services/runtime/Dockerfile`, root `.dockerignore`, `compose/recon.yml`). Refactor C (top-level docker-build fallback) is explicitly DEFERRED — do not implement.

**Tech Stack:** GNU Make, Python venvs (created by per-service Makefiles), Java + Saxon HE (FAST only), Datasette runtime container (unchanged).

**Design decisions (user-approved):**
1. **Copy after build** — each service builds into its own dir as today; root Makefile copies the `.db` to `data/`. Dumb and safe.
2. **Minimal stubs** — per-service READMEs become ~10 lines: what it is, data source, license, link to root README.

**DB output paths (from per-service Makefiles, unchanged):**

| Service | Native build output | Copied to |
|---------|--------------------|-----------|
| fast | `services/fast/data/fast.db` (`DATA_DIR ?= data`) | `data/fast.db` |
| geonames | `services/geonames/geonames.db` (`DATA_DIR ?= .`) | `data/geonames.db` |
| isolang | `services/isolang/data/iso639.db` (`DATA_DIR := data`) | `data/iso639.db` |

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `Makefile` (root) | Modify | `data` target drives native builds + copy; per-service `data-<name>` targets |
| `services/fast/Dockerfile` | Delete | Builder image no longer used |
| `services/geonames/Dockerfile` | Delete | Builder image no longer used |
| `services/isolang/Dockerfile` | Delete | Builder image no longer used |
| `services/fast/.dockerignore` | Delete | Only served the deleted builder build |
| `services/geonames/.dockerignore` | Delete | Only served the deleted builder build |
| `services/isolang/.dockerignore` | Delete | Only served the deleted builder build |
| `services/fast/Makefile` | Modify | Remove dead `DOCKER=1` toggle blocks |
| `services/geonames/Makefile` | Modify | Remove dead `DOCKER=1` toggle blocks |
| `services/isolang/Makefile` | Modify | Remove dead `DOCKER=1` toggle blocks |
| `README.md` (root) | Rewrite | Single consolidated doc: usage, requirements, type tables, OpenRefine, troubleshooting |
| `services/fast/README.md` | Rewrite | ~10-line stub, keep data/source citations |
| `services/geonames/README.md` | Rewrite | ~10-line stub, keep data/source citations |
| `services/isolang/README.md` | Rewrite | ~10-line stub, keep data/source citations |

Unchanged: `services/runtime/*`, `compose/recon.yml`, root `.dockerignore`, all `*.metadata.json`, `build_db.py`, `xslt/`.

---

### Task 1: Root Makefile — native `data` target

**Files:**
- Modify: `Makefile` (root)

- [ ] **Step 1: Replace the `data` target with native per-service targets**

Replace the entire root `Makefile` content with:

```make
# Reconciliation Services -- native dataset builds + single Datasette runtime
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
# Datasets are built NATIVELY (no Docker) by each service's own Makefile,
# then copied into data/ for the runtime to serve. See README for host
# requirements (FAST needs Java + Saxon).
#
# Deploying elsewhere (e.g. Raspberry Pi): `make data && make build && make save`
# on a workstation, copy dist/recon-runtime.tar.gz + data/*.db to the target,
# `docker load`, then `make up` from a checkout of this repo. The .db files
# are architecture-independent; only the (small) runtime image is per-arch.

SERVICES ?= fast geonames isolang

# Compose resolves the default .env against the compose file directory,
# not the repo root, so pass it explicitly.
COMPOSE := docker compose -p recon $(if $(wildcard .env),--env-file .env) -f compose/recon.yml

.PHONY: data data-fast data-geonames data-isolang \
        build up down logs status save clean clean-data

# Each dataset builds natively in its own directory (incremental: each
# service's Makefile skips completed downloads/stages), then the .db is
# copied to data/ for the runtime.
data: $(addprefix data-,$(SERVICES))
	@ls -lh data/*.db

data-fast:
	$(MAKE) -C services/fast build
	@mkdir -p data
	cp services/fast/data/fast.db data/fast.db

data-geonames:
	$(MAKE) -C services/geonames build
	@mkdir -p data
	cp services/geonames/geonames.db data/geonames.db

data-isolang:
	$(MAKE) -C services/isolang build
	@mkdir -p data
	cp services/isolang/data/iso639.db data/iso639.db

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

Notes:
- `data: $(addprefix data-,$(SERVICES))` preserves `SERVICES="isolang"` filtering.
- `cp` (not `mv`): per-service incremental state stays intact; cost is the .db existing twice on disk (geonames ~4GB ×2). Documented in README (Task 5).
- The geonames copy source is `services/geonames/geonames.db` — that Makefile's `DATA_DIR ?= .`.

- [ ] **Step 2: Verify make parses and target wiring**

Run: `make -n data SERVICES="isolang"`
Expected: dry-run prints `make -C services/isolang build`, `mkdir -p data`, `cp services/isolang/data/iso639.db data/iso639.db`, `ls -lh data/*.db`. No errors.

- [ ] **Step 3: Commit**

```bash
git add Makefile
git commit -m "feat(make): data target builds datasets natively, copies .db to data/"
```

---

### Task 2: Delete builder Dockerfiles and per-service .dockerignore files

**Files:**
- Delete: `services/fast/Dockerfile`, `services/geonames/Dockerfile`, `services/isolang/Dockerfile`
- Delete: `services/fast/.dockerignore`, `services/geonames/.dockerignore`, `services/isolang/.dockerignore`

- [ ] **Step 1: Remove the files**

```bash
git rm services/fast/Dockerfile services/geonames/Dockerfile services/isolang/Dockerfile \
       services/fast/.dockerignore services/geonames/.dockerignore services/isolang/.dockerignore
```

- [ ] **Step 2: Verify the runtime image still builds (it never referenced these)**

Run: `make build`
Expected: `recon-runtime` builds successfully (cached layers fine). The runtime Dockerfile COPYs only `services/runtime/*` and `services/*/*.metadata.json`, so deletions are inert.

- [ ] **Step 3: Verify no remaining references to deleted files**

Run: `grep -rn "services/fast/Dockerfile\|services/geonames/Dockerfile\|services/isolang/Dockerfile\|--target export" Makefile compose/ services/runtime/ || echo CLEAN`
Expected: `CLEAN` (README references fixed in Tasks 5-6).

- [ ] **Step 4: Commit**

```bash
git commit -m "refactor: drop per-dataset builder Dockerfiles

Native make is the only data pipeline; the runtime container is the
sole Docker artifact. Removes the Docker-VM RAM/disk requirements for
the FAST build (native java -Xmx8g uses host RAM directly)."
```

---

### Task 3: Remove dead DOCKER=1 toggles from service Makefiles

The `DOCKER=1` mode existed solely for the deleted builder Dockerfiles. Remove the toggles; keep only the venv branch. Per-service paths/targets otherwise untouched (user decision: "per-service make stays untouched" beyond this dead-code removal).

**Files:**
- Modify: `services/fast/Makefile`
- Modify: `services/geonames/Makefile`
- Modify: `services/isolang/Makefile`

- [ ] **Step 1: fast — header comment**

In `services/fast/Makefile` remove these lines (16-20):

```make
#
# Usage (Docker):
#   Data is downloaded and transformed at IMAGE BUILD time (see Dockerfile);
#   the runtime container serves the pre-built database directly via datasette
#   (no make/Java inside the runtime image).
```

- [ ] **Step 2: fast — DOCKER variable**

Remove:

```make
# Docker mode: when DOCKER=1, skip venv and use system tools
DOCKER ?=

```

- [ ] **Step 3: fast — tool paths block**

Replace:

```make
ifdef DOCKER
  PYTHON := python3
  PIP := pip
  DATASETTE := datasette
  SQLITE_UTILS := sqlite-utils
  VENV_DONE :=
  # Use saxon wrapper script (includes xmlresolver jars in classpath)
  SAXON ?= saxon
else
  PYTHON := $(VENV_DIR)/bin/python3
  PIP := $(VENV_DIR)/bin/pip
  DATASETTE := $(VENV_DIR)/bin/datasette
  SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
  VENV_DONE := $(VENV_DIR)/.done
  # macOS Homebrew Saxon path
  SAXON_JAR = $(shell ls /opt/homebrew/opt/saxon/libexec/saxon-he-*.jar 2>/dev/null | grep -v test | grep -v xqj | head -1)
  SAXON := java -Xmx8g -jar $(SAXON_JAR)
endif
```

with:

```make
PYTHON := $(VENV_DIR)/bin/python3
PIP := $(VENV_DIR)/bin/pip
DATASETTE := $(VENV_DIR)/bin/datasette
SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
VENV_DONE := $(VENV_DIR)/.done
# macOS Homebrew Saxon path
SAXON_JAR = $(shell ls /opt/homebrew/opt/saxon/libexec/saxon-he-*.jar 2>/dev/null | grep -v test | grep -v xqj | head -1)
SAXON := java -Xmx8g -jar $(SAXON_JAR)
```

- [ ] **Step 4: fast — status line**

Replace:

```make
	@if [ -n "$(VENV_DONE)" ] && [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; elif [ -z "$(VENV_DONE)" ]; then echo "  ✓ system (Docker)"; else echo "  ✗ venv"; fi
```

with:

```make
	@if [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
```

- [ ] **Step 5: fast — venv recipe conditional**

In the `$(VENV_DIR)/.done:` recipe, remove the `ifndef DOCKER` line and its matching `endif` (keeping the Saxon/Java check lines between them, dedented stays as-is since they're recipe lines).

- [ ] **Step 6: fast — help text**

Remove these lines from the `help` target:

```make
	@echo "Docker usage:"
	@echo "  docker compose up           Build and start service"
	@echo "  docker compose run --rm fast make status"
	@echo ""
```

- [ ] **Step 7: geonames — header comment**

In `services/geonames/Makefile` remove lines 14-18:

```make
#
# Usage (Docker):
#   Data is downloaded and the database built at IMAGE BUILD time (see
#   Dockerfile); the runtime container serves the pre-built database directly.
#   docker compose run --rm geonames make status   (still works in-container)
```

- [ ] **Step 8: geonames — DOCKER variable**

Remove:

```make
# Docker mode: when DOCKER=1, skip venv and use system Python
DOCKER ?=

```

- [ ] **Step 9: geonames — tool paths block**

Replace:

```make
ifdef DOCKER
  PYTHON := python3
  PIP := pip
  DATASETTE := datasette
  SQLITE_UTILS := sqlite-utils
  VENV_DONE :=
else
  PYTHON := $(VENV_DIR)/bin/python3
  PIP := $(VENV_DIR)/bin/pip
  DATASETTE := $(VENV_DIR)/bin/datasette
  SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
  VENV_DONE := $(VENV_DIR)/.done
endif
```

with:

```make
PYTHON := $(VENV_DIR)/bin/python3
PIP := $(VENV_DIR)/bin/pip
DATASETTE := $(VENV_DIR)/bin/datasette
SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
VENV_DONE := $(VENV_DIR)/.done
```

- [ ] **Step 10: geonames — status target conditionals**

Replace:

```make
ifdef DOCKER
	@echo "  ✓ Docker mode (system Python)"
else
	@if [ -f $(VENV_DIR)/.done ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
endif
```

with:

```make
	@if [ -f $(VENV_DIR)/.done ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
```

And in the same target, remove the `ifndef DOCKER` / `endif` lines wrapping the trailing "Versions:" block (keep the block).

- [ ] **Step 11: geonames — clean-all conditional**

Replace:

```make
ifndef DOCKER
	@rm -rf $(VENV_DIR)
endif
```

with:

```make
	@rm -rf $(VENV_DIR)
```

- [ ] **Step 12: geonames — venv recipe wrapper**

Remove the `ifndef DOCKER` line before `$(VENV_DIR)/.done:` and the matching `endif` after the recipe (keep the recipe).

- [ ] **Step 13: geonames — help text**

Remove:

```make
	@echo "Docker usage:"
	@echo "  docker compose up           Build and start service"
	@echo "  docker compose run --rm geonames make status"
	@echo ""
```

- [ ] **Step 14: isolang — DOCKER variable and tool paths**

In `services/isolang/Makefile` replace:

```make
# Docker mode: when DOCKER=1, skip venv and use system Python
DOCKER ?=

ifdef DOCKER
  PYTHON := python3
  PIP := pip
  DATASETTE := datasette
  SQLITE_UTILS := sqlite-utils
  VENV_DONE :=
else
  PYTHON := $(VENV_DIR)/bin/python3
  PIP := $(VENV_DIR)/bin/pip
  DATASETTE := $(VENV_DIR)/bin/datasette
  SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
  VENV_DONE := $(VENV_DIR)/.done
endif
```

with:

```make
PYTHON := $(VENV_DIR)/bin/python3
PIP := $(VENV_DIR)/bin/pip
DATASETTE := $(VENV_DIR)/bin/datasette
SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
VENV_DONE := $(VENV_DIR)/.done
```

- [ ] **Step 15: isolang — status line**

Replace:

```make
	@if [ -n "$(VENV_DONE)" ] && [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; elif [ -z "$(VENV_DONE)" ]; then echo "  ✓ system (Docker)"; else echo "  ✗ venv"; fi
```

with:

```make
	@if [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
```

- [ ] **Step 16: isolang — venv recipe wrapper**

Remove the `ifndef DOCKER` line before `$(VENV_DIR)/.done:` and the matching `endif` after the recipe (keep the recipe).

- [ ] **Step 17: Verify no DOCKER references remain and Makefiles parse**

Run: `grep -n "DOCKER" services/fast/Makefile services/geonames/Makefile services/isolang/Makefile || echo CLEAN`
Expected: `CLEAN`

Run: `make -C services/fast -n status >/dev/null && make -C services/geonames -n status >/dev/null && make -C services/isolang -n status >/dev/null && echo PARSE-OK`
Expected: `PARSE-OK`

- [ ] **Step 18: Commit**

```bash
git add services/fast/Makefile services/geonames/Makefile services/isolang/Makefile
git commit -m "refactor(make): remove dead DOCKER=1 toggles from service Makefiles

Only consumer was the deleted builder Dockerfiles."
```

---

### Task 4: End-to-end verification (isolang native build)

isolang is the cheap dataset (<2 min) — full pipeline proof. geonames/fast native builds are expensive; not exercised here (geonames `data/geonames.db` already exists from the Docker-era build and remains valid; fast needs the manual zip download).

- [ ] **Step 1: Clean isolang state and rebuild via root Makefile**

```bash
rm -f data/iso639.db
make data SERVICES="isolang"
```

Expected: venv setup (or reuse), three downloads (or cached), `build_db.py` runs, FTS index created, then `cp services/isolang/data/iso639.db data/iso639.db`, final `ls -lh data/*.db` shows `iso639.db` (~1-3MB) and `geonames.db`.

- [ ] **Step 2: Restart runtime and verify endpoint**

```bash
make down && make up
sleep 60   # immutable mode counts 13M geonames rows at startup
curl -sf "http://127.0.0.1:8000/iso639/languages/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22Welsh%22%7D%7D"
```

Expected: HTTP 200, JSON with `q0` result containing id `cym`, score 100.

- [ ] **Step 3: Verify geonames endpoint still serves (pre-existing .db untouched)**

```bash
curl -sf "http://127.0.0.1:8000/geonames/geonames/-/reconcile?queries=%7B%22q0%22%3A%7B%22query%22%3A%22London%22%7D%7D" | head -c 300
```

Expected: HTTP 200, JSON result containing id `11591955` near top.

- [ ] **Step 4: No commit needed (verification only); confirm clean tree**

Run: `git status`
Expected: clean (data/ is gitignored).

---

### Task 5: Consolidated root README

**Files:**
- Rewrite: `README.md` (root)

- [ ] **Step 1: Replace README.md content entirely with:**

````markdown
# Reconciliation Services

W3C Reconciliation Service API endpoints for OpenRefine. One Datasette container serves every dataset on a single port; each dataset is built **natively** by its own Makefile into an SQLite file in `data/`. Docker is used only for the thin runtime.

## Endpoints

All on one port (default 8000):

| Dataset | Endpoint |
|---------|----------|
| OCLC FAST subject headings | `/fast/FAST/-/reconcile` (+ per-facet endpoints below) |
| GeoNames geographic features | `/geonames/geonames/-/reconcile` |
| ISO 639 language codes | `/iso639/languages/-/reconcile` |

## Quick Start

```bash
make data        # Build all dataset .db files into data/ (native; see Requirements)
make build       # Build the runtime image
make up          # Start serving on http://127.0.0.1:8000/
```

## Usage

```bash
make data                            # Build all dataset databases (native)
make data SERVICES="isolang"         # Build one dataset
make build                           # Build the runtime image
make up / make down                  # Start / stop
make logs / make status              # Inspect
make save                            # Export runtime image to dist/
make clean                           # Stop + remove runtime image
make clean-data                      # Remove built .db files from data/
```

Refreshing one dataset: `make data SERVICES="geonames" && make down && make up`.
No image rebuild needed — the runtime picks up whatever `.db` files are in `data/`.

Datasets build incrementally: each service's Makefile skips downloads and pipeline stages that are already done. `make -C services/<name> clean` removes only that service's local `.db`; `clean-all` removes downloads and venv too.

## Build Requirements (native)

All datasets: macOS or Linux with `python3` (3.10+), `curl`, `unzip`, `sqlite3`, `make`. Each service creates its own Python venv automatically.

**FAST additionally:** Java JDK + Saxon HE (`brew install saxon` on macOS; the build checks and offers to install). The XSLT step runs `java -Xmx8g` — 12-16GB host RAM recommended.

| Dataset | Build Time | .db Size | Data Source | License |
|---------|-----------|----------|-------------|---------|
| isolang | < 2 min | ~3MB | LOC, SIL International | public standards data |
| geonames | ~12 min | ~4GB | GeoNames.org | CC BY 4.0 |
| fast | 30-60 min | ~1.5GB | OCLC FAST | ODC-BY |

Disk: intermediates stay in each service directory (geonames ~2GB downloads, fast ~8GB zip/MARC/SKOS/CSV); the final `.db` is *copied* to `data/`, so it exists twice while service-side copies are kept.

### FAST: manual download required (Cloudflare)

OCLC blocks automated downloads (the build fails within seconds if so). Download in a browser:

- https://researchworks.oclc.org/researchdata/fast/FASTAll.marcxml.zip (~198MB)

Save it to `services/fast/data/FASTAll.marcxml.zip`, then re-run `make data SERVICES="fast"`.

## Using with OpenRefine

1. Start the service (`make up`)
2. Column dropdown → **Reconcile** → **Start reconciling...**
3. Click **Add Standard Service...** and enter an endpoint URL from the table above (e.g. `http://127.0.0.1:8000/fast/FAST/-/reconcile`)
4. Optionally filter by type (tables below)

Sample data for testing: `services/geonames/test-data.csv` (~8000 place names including historical forms — Batavia→Jakarta, Canton→Guangzhou).

## Type Filtering

### FAST facets

| Type | Description | Example |
|------|-------------|---------|
| `Topical` | Subjects, concepts, activities | "Climate change", "Jazz music" |
| `Personal` | People, authors, historical figures | "Shakespeare, William" |
| `Corporate` | Organizations, companies | "United Nations" |
| `Geographic` | Places, regions, countries | "London (England)" |
| `Event` | Wars, conferences, events | "World War, 1939-1945" |
| `Chronological` | Time periods, eras | "Twentieth century" |
| `Title` | Works, publications | "Hamlet" |
| `FormGenre` | Document types, formats | "Dictionaries" |
| `Meeting` | Conferences, symposia | "Olympic Games" |

Facet-specific endpoints also exist for targeted reconciliation:
`/fast/FASTTopical/-/reconcile`, `/fast/FASTPersonal/-/reconcile`, `/fast/FASTGeographic/-/reconcile`, `/fast/FASTCorporate/-/reconcile`, `/fast/FASTEvent/-/reconcile`, `/fast/FASTChronological/-/reconcile`, `/fast/FASTTitle/-/reconcile`, `/fast/FASTFormGenre/-/reconcile`, `/fast/FASTMeeting/-/reconcile`

### GeoNames feature classes

| Type | Description |
|------|-------------|
| `P` | Populated places (cities, towns, villages) |
| `A` | Administrative divisions (countries, states) |
| `H` | Hydrographic (rivers, lakes, seas) |
| `T` | Terrain (mountains, valleys, islands) |
| `L` | Areas (parks, reserves, regions) |
| `S` | Structures (buildings, airports) |
| `R` | Roads/railroads |
| `V` | Vegetation (forests, grasslands) |
| `U` | Undersea features |

### ISO 639 parts

| Type | Description | Authority |
|------|-------------|-----------|
| `ISO 639-2` | Individual languages (~500 codes) | Library of Congress |
| `ISO 639-3` | All known languages (~7500 codes) | SIL International |
| `ISO 639-5` | Language families/groups (~115 codes) | Library of Congress |

Codes are unique across the database: if a code exists in multiple parts (e.g. `eng`), it appears once with the type from the first standard that defined it (639-2 takes precedence).

## Developing a Single Dataset

Each service directory is self-contained for development:

```bash
cd services/<name>
make build     # venv + download + build (incremental)
make serve     # standalone Datasette on port 8001 (PUBLIC=1 for network access)
make status    # pipeline/db stats
make test      # FTS + endpoint smoke test (fast, geonames)
make clean     # remove local .db only
make clean-all # remove everything incl. downloads and venv
```

FAST pipeline stages can be run individually for debugging: `make download`, `make extract`, `make skos`, `make csv`, `make build`. The pipeline is MARC XML → SKOS (`xslt/fast2skos.xsl`) → CSV (`xslt/skos2csv-reconcile.xsl`) → SQLite + FTS5; see `services/fast/xslt/docs/` for transformation notes.

## Configuration

Copy `.env.example` to `.env` to customize the port (default `RECON_PORT=8000`):

```bash
cp .env.example .env
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
is per-arch. An Apple Silicon Mac builds `arm64` natively, correct for Pi 5;
for an `amd64` server, cross-build with:

```bash
docker buildx build --platform linux/amd64 --load -t recon-runtime:latest -f services/runtime/Dockerfile .
```

Refreshing one dataset later: rebuild just that `.db` on the workstation,
scp it across, restart (`make down && make up`) — no image transfer needed.

## Upgrading from per-service containers

Earlier versions ran one container per dataset with data baked into each
image. Remove them before first `make up` with this version:

```bash
docker compose -p recon down
docker rmi recon-fast:latest recon-geonames:latest recon-isolang:latest
```

## Adding a Dataset

1. Create `services/<name>/` with a Makefile whose `build` target produces
   the dataset's `.db` (plus a `serve` target for standalone dev, by convention)
2. Add `services/<name>/<name>.metadata.json` with a `databases` section
   (see existing services; the runtime merges all of them at image build)
3. Add a `data-<name>` target to the root Makefile (build + copy the `.db`
   to `data/`) and add `<name>` to `SERVICES`
4. `make data SERVICES="<name>" && make build && make down && make up`
5. Update this README

## Data Licenses

- **FAST:** OCLC Research, [ODC-BY](https://opendatacommons.org/licenses/by/1-0/) — https://www.oclc.org/research/areas/data-science/fast.html
- **GeoNames:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — https://www.geonames.org/
- **ISO 639:** Library of Congress and SIL International standards data

## References

- [W3C Reconciliation API](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/) - Specification
- [OpenRefine reconciliation docs](https://docs.openrefine.org/manual/reconciling)
- [Datasette](https://datasette.io/) + [datasette-reconcile](https://github.com/drkane/datasette-reconcile)
- [SQLite FTS5](https://sqlite.org/fts5.html)
- [OCLC searchFAST](https://fast.oclc.org/searchfast/)
- [ISO 639](https://www.iso.org/iso-639-language-code) / [ISO 639-2 (LOC)](https://www.loc.gov/standards/iso639-2/) / [ISO 639-3 (SIL)](https://iso639-3.sil.org/) / [ISO 639-5 (LOC)](https://www.loc.gov/standards/iso639-5/)
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: consolidate all service documentation into root README

Single source for usage, native build requirements, type tables,
OpenRefine setup, and FAST Cloudflare workaround (one zip location
now that the Docker build path is gone)."
```

---

### Task 6: Per-service README stubs

**Files:**
- Rewrite: `services/fast/README.md`
- Rewrite: `services/geonames/README.md`
- Rewrite: `services/isolang/README.md`

- [ ] **Step 1: Replace `services/fast/README.md` with:**

```markdown
# FAST Dataset Builder

Builds `fast.db`: [OCLC FAST](https://www.oclc.org/research/areas/data-science/fast.html) (Faceted Application of Subject Terminology) subject headings — 2M+ authority records in 9 facets. Pipeline: MARC XML → SKOS → CSV → SQLite FTS5 (Saxon XSLT).

- Build from repo root: `make data SERVICES="fast"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Source zip usually needs a manual browser download (Cloudflare) — see root README
- Requires Java + Saxon HE; XSLT notes in `xslt/docs/`
- License: [ODC-BY](https://opendatacommons.org/licenses/by/1-0/), credit OCLC Research

Full usage, requirements, facet tables, and troubleshooting: [repo root README](../../README.md).
```

- [ ] **Step 2: Replace `services/geonames/README.md` with:**

```markdown
# GeoNames Dataset Builder

Builds `geonames.db`: [GeoNames](https://www.geonames.org/) geographic features — 13M+ places with FTS5 full-text search, filterable by feature class.

- Build from repo root: `make data SERVICES="geonames"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Test data: `test-data.csv` (~8000 place names incl. historical forms)
- License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), credit GeoNames.org

Full usage, feature-class table, and OpenRefine setup: [repo root README](../../README.md).
```

- [ ] **Step 3: Replace `services/isolang/README.md` with:**

```markdown
# ISO 639 Dataset Builder

Builds `iso639.db`: ISO 639 language codes — parts 639-2 (LOC), 639-3 (SIL, ~7500 languages), and 639-5 (language families), deduplicated into one `languages` table with FTS5.

- Build from repo root: `make data SERVICES="isolang"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Sources: loc.gov (639-2, 639-5), iso639-3.sil.org (639-3) — public standards data

Full usage, type table, and OpenRefine setup: [repo root README](../../README.md).
```

- [ ] **Step 4: Verify no stale Docker-build references remain anywhere**

Run: `grep -rn "target export\|DOCKER=1\|recon-fast\|recon-geonames\|recon-isolang" README.md services/*/README.md services/*/Makefile Makefile | grep -v "docker rmi" || echo CLEAN`
Expected: `CLEAN` (the only intentional old-image-name mentions are on the `docker rmi` line in the root README "Upgrading" section, filtered out).

- [ ] **Step 5: Commit**

```bash
git add services/fast/README.md services/geonames/README.md services/isolang/README.md
git commit -m "docs: reduce per-service READMEs to stubs pointing at root README"
```

---

## Out of Scope (deferred — do NOT implement)

- **Refactor C:** top-level Docker fallback build pipeline for datasets. User: "I don't want to do this yet." Re-adding later means new builder Dockerfiles; acceptable cost.
- Normalizing geonames `DATA_DIR` to `data/` (its `.db` and downloads live in the service root) — works as-is; user chose untouched per-service paths.
- Building geonames/fast natively as part of verification (expensive; existing `data/geonames.db` remains valid, fast needs manual zip).

## Verification Summary

| Check | Command | Expected |
|-------|---------|----------|
| Root make parses | `make -n data SERVICES="isolang"` | dry-run shows sub-make + cp |
| Runtime builds | `make build` | recon-runtime OK |
| No DOCKER refs | `grep -n DOCKER services/*/Makefile` | none |
| isolang e2e | Task 4 steps | Welsh→cym score 100 |
| geonames still served | Task 4 step 3 | London→11591955 |
| Clean tree | `git status` | clean |
