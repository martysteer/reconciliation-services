# GeoNames Reconciliation Service

A local reconciliation service for [GeoNames](https://www.geonames.org/) geographic data, compatible with [OpenRefine](https://openrefine.org/) and the [W3C Reconciliation Service API v0.2](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/).

Match place names against 13+ million geographic features with full-text search.

## Features
- **Full-text search** with [FTS5](https://sqlite.org/fts5.html) for fast, fuzzy matching
- **Type filtering** by GeoNames feature class (populated places, administrative, hydrographic, etc.)
- **OpenRefine compatible** via datasette-reconcile plugin
- **Self-contained** SQLite database built in Docker, or native Python venv
- **Offline operation** - works without internet after initial setup

## Quick Start

### Option 1: Docker (recommended)

This directory builds the dataset (`geonames.db`, ~12 min); serving is done
by the shared runtime container (see repo root README).

```bash
# From the repo root:
make data SERVICES="geonames"   # build data/geonames.db
make build && make up           # build + start the shared runtime

# Or standalone from this directory (writes ../../data/geonames.db):
docker build --target export --output type=local,dest=../../data .
```

Endpoint: `http://127.0.0.1:8000/geonames/geonames/-/reconcile`

### Option 2: Native (macOS/Linux)

```bash
make build                  # Downloads data, creates venv, builds DB
make serve                  # Start server
```

Endpoint: `http://127.0.0.1:8001/geonames/geonames/-/reconcile`

## Using with OpenRefine

1. Column dropdown → **Reconcile** → **Start reconciling...**
2. Click **Add Standard Service...**
3. Enter the endpoint URL (port 8000 for Docker, 8001 for native)

## Testing

A sample dataset `test-data.csv` is included with ~8000 geographic place names for testing:

1. Start the service (`make up` from repo root, or `make serve`)
2. Open OpenRefine and create a new project from `test-data.csv`
3. Reconcile the **City** or **Country** column against the service
4. Optionally filter by type (e.g., `P` for populated places, `A` for administrative)

The test data includes historical names (Batavia→Jakarta, Canton→Guangzhou), modern place names, and various administrative levels - useful for validating fuzzy matching and type filtering.

## Commands

Docker commands run from the **repo root**; native commands from this directory.
Data is exported to `data/geonames.db` and served by the shared runtime —
to refresh data, re-run `make data` and restart.

| Docker (repo root) | Native | Description |
|--------------------|--------|-------------|
| `make data SERVICES="geonames"` | `make build` | Build (data pipeline) |
| `make build && make up` | `make serve` | Run |
| `make down` | Ctrl+C | Stop |
| `make data SERVICES="geonames"` (re-run) | `make update` | Re-download data |
| `make clean && make clean-data` | `make clean-all` | Remove everything |
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

**Disk space:** ~5GB during build (400MB download → 1.5GB extracted → 3GB database); only the ~3GB `geonames.db` is exported to `data/`

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
