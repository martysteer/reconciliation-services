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
make save                            # Export images to dist/ for transfer
make clean                           # Stop services + remove images (fresh-build reset)
```

## Configuration

Copy `.env.example` to `.env` to customize ports:

```bash
cp .env.example .env
```

Default ports: FAST=8001, GeoNames=8002, ISO-lang=8003.

## Build Requirements

All data pipelines run at **image build time** — images are fully self-contained and start instantly with no runtime downloads or transforms.

Images are built on a capable machine (12-16GB RAM recommended for FAST service XSLT transform). Runtime target is Raspberry Pi 5 (8GB) or cloud.

| Service | Build Time | Image Size | Data Source |
|---------|-----------|------------|-------------|
| isolang | < 2 min | ~200MB | LOC, SIL International |
| geonames | ~12 min | ~4.6GB | GeoNames.org |
| fast | 30-60 min | ~2GB | OCLC FAST |

Notes:

- **FAST on Docker Desktop (macOS/Windows):** raise the Docker VM memory limit to at least 12GB (Settings → Resources) before building — the XSLT step runs Java with `-Xmx8g`. The builder stage also needs ~10GB of free Docker disk for intermediate files (zip, MARC XML, SKOS, CSV); these never reach the final image.
- **FAST download blocked by Cloudflare:** OCLC blocks automated downloads (the build fails within seconds if so). Download `FASTAll.marcxml.zip` manually in a browser and place it at `services/fast/FASTAll.marcxml.zip` — the Docker build picks it up automatically and skips the download. (The error text inside the build mentions `/app/data/...` — that is the in-container path for native builds; for Docker builds use the host path above.)

## Upgrading from per-service compose projects

Earlier versions ran each service as its own compose project with named data
volumes. Before first `make up` with this version, remove the old containers
and volumes (data now lives inside the images):

```bash
for p in recon-fast recon-geonames recon-isolang; do docker compose -p $p down -v; done
```

## Deploying to a Pi / Server (build on laptop, copy image)

The Pi 5 (8GB) cannot build the FAST or GeoNames images itself. Build on a
workstation, export, and copy the images across — no registry needed.

**1. On the laptop — build and export:**

```bash
make build                      # build all images (or SERVICES="fast")
make save                       # exports dist/recon-<service>.tar.gz
```

**2. Copy to the target machine:**

```bash
scp dist/recon-*.tar.gz pi@raspberrypi.local:~
```

**3. On the Pi — load and run:**

```bash
docker load < recon-fast.tar.gz
docker load < recon-geonames.tar.gz
docker load < recon-isolang.tar.gz

# from a checkout of this repo (compose files + .env only; no build happens)
make up
```

`make up` uses the loaded `recon-<service>:latest` images directly; Docker
Compose only builds if an image is missing.

**Architecture note:** images must match the target CPU. An Apple Silicon Mac
builds `arm64` images natively — correct for Pi 5. For an `amd64` server,
cross-build with:

```bash
docker buildx build --platform linux/amd64 --load -t recon-isolang:latest services/isolang
```

## Adding a Service

1. Create `services/<name>/` with Dockerfile and service code
2. Create `compose/<name>.yml`
3. Add port default to `.env.example`
4. Update this README
