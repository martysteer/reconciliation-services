# Reconciliation Services

W3C Reconciliation Service API endpoints for OpenRefine. One Datasette container serves every dataset on a single port; each dataset is built by its own builder image into an SQLite file in `data/`.

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

Copy `.env.example` to `.env` to customize the port (default `RECON_PORT=8000`):

```bash
cp .env.example .env
```

## Build Requirements

All data pipelines run inside builder images (`make data`); the resulting `.db` files are exported to `data/` and bind-mounted into the runtime. Datasets are built on a capable machine (12-16GB RAM recommended for the FAST XSLT transform). Runtime target is Raspberry Pi 5 (8GB) or cloud.

| Dataset | Build Time | .db Size | Data Source |
|---------|-----------|----------|-------------|
| isolang | < 2 min | ~3MB | LOC, SIL International |
| geonames | ~12 min | ~3GB | GeoNames.org |
| fast | 30-60 min | ~1.5GB | OCLC FAST |

The runtime image itself is ~200MB and contains no data.

Notes:

- **FAST on Docker Desktop (macOS/Windows):** raise the Docker VM memory limit to at least 12GB (Settings → Resources) before building — the XSLT step runs Java with `-Xmx8g`. The builder also needs ~10GB of free Docker disk for intermediate files (zip, MARC XML, SKOS, CSV); these never reach `data/`.
- **FAST download blocked by Cloudflare:** OCLC blocks automated downloads (the build fails within seconds if so). Download `FASTAll.marcxml.zip` manually in a browser and place it at `services/fast/FASTAll.marcxml.zip` — the Docker build picks it up automatically and skips the download. (The error text inside the build mentions `/app/data/...` — that is the in-container path for native builds; for Docker builds use the host path above.)

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
is per-arch. An Apple Silicon Mac builds `arm64` natively, correct for Pi 5;
for an `amd64` server, cross-build with:

```bash
docker buildx build --platform linux/amd64 --load -t recon-runtime:latest -f services/runtime/Dockerfile .
```

Refreshing one dataset later: rebuild just that `.db` on the workstation,
scp it across, restart (`make down && make up`) — no image transfer needed.

## Adding a Dataset

1. Create `services/<name>/` with a builder Dockerfile ending in:
   `FROM scratch AS export` + `COPY --from=builder /app/data/<name>.db /`
2. Add `services/<name>/<name>.metadata.json` with a `databases` section
   (see existing services; the runtime merges all of them at image build)
3. `make data SERVICES="<name>" && make build && make down && make up`
4. Update this README
