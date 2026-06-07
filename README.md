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
