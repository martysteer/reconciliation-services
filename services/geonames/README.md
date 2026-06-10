# GeoNames Reconciliation Service

A local reconciliation service for [GeoNames](https://www.geonames.org/) geographic data, compatible with [OpenRefine](https://openrefine.org/) and the [W3C Reconciliation Service API v0.2](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/).

Match place names against 13+ million geographic features with full-text search.

## Features
- **Full-text search** with [FTS5](https://sqlite.org/fts5.html) for fast, fuzzy matching
- **Type filtering** by GeoNames feature class (populated places, administrative, hydrographic, etc.)
- **OpenRefine compatible** via datasette-reconcile plugin
- **Self-contained** Docker image with baked-in database, or native Python venv
- **Offline operation** - works without internet after initial setup

## Quick Start

### Option 1: Docker (recommended)

The full data pipeline runs at **image build time** (~12 min) — the resulting
image is self-contained (~4.6GB) and starts instantly.

```bash
# From the repo root (compose files live in compose/):
make build SERVICES="geonames" && make up SERVICES="geonames"

# Or standalone from this directory:
docker build -t recon-geonames .
docker run -d -p 8002:8001 recon-geonames
```

Endpoint: `http://127.0.0.1:8002/geonames/geonames/-/reconcile`

### Option 2: Native (macOS/Linux)

```bash
make build                  # Downloads data, creates venv, builds DB
make serve                  # Start server
```

Endpoint: `http://127.0.0.1:8001/geonames/geonames/-/reconcile`

## Using with OpenRefine

1. Column dropdown → **Reconcile** → **Start reconciling...**
2. Click **Add Standard Service...**
3. Enter the endpoint URL (port 8002 for Docker, 8001 for native)

## Testing

A sample dataset `test-data.csv` is included with ~8000 geographic place names for testing:

1. Start the service (`make up SERVICES="geonames"` from repo root, or `make serve`)
2. Open OpenRefine and create a new project from `test-data.csv`
3. Reconcile the **City** or **Country** column against the service
4. Optionally filter by type (e.g., `P` for populated places, `A` for administrative)

The test data includes historical names (Batavia→Jakarta, Canton→Guangzhou), modern place names, and various administrative levels - useful for validating fuzzy matching and type filtering.

## Commands

Docker commands run from the **repo root**; native commands from this directory.
Data is baked into the image at build time — to refresh data, rebuild the image.

| Docker (repo root) | Native | Description |
|--------------------|--------|-------------|
| `make build SERVICES="geonames"` | `make build` | Build (data pipeline) |
| `make up SERVICES="geonames"` | `make serve` | Run |
| `make down SERVICES="geonames"` | Ctrl+C | Stop |
| `make build SERVICES="geonames"` (rebuild) | `make update` | Re-download data |
| `make clean SERVICES="geonames"` | `make clean-all` | Remove everything |
| — | `make status` | Show pipeline/db stats |

## Feature Types

Filter reconciliation by GeoNames feature class:

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

## Requirements

**Docker:** Docker Desktop (Windows, macOS, Linux)

**Native:** Python 3.10+, curl, unzip, make (macOS/Linux only)

**Disk space:** ~5GB during build (400MB download → 1.5GB extracted → 3GB database); the Docker image keeps only the database (~4.6GB image total)

## Data License

GeoNames data is [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Credit: https://www.geonames.org/

## References

- [datasette](https://datasette.io/) - Tool for exploring and publishing data
- [datasette-reconcile](https://github.com/drkane/datasette-reconcile) - Reconciliation API plugin
- [GeoNames](https://www.geonames.org/) - Geographic database
- [OpenRefine](https://openrefine.org/) - Data cleaning tool

- [OpenRefine Reconciliation Documentation](https://docs.openrefine.org/manual/reconciling)
- [SQLite FTS5](https://sqlite.org/fts5.html) - SQLite full text search
- [W3C Reconciliation API](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/) - Specification
