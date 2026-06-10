# FAST Reconciliation Service

A local reconciliation service for [OCLC FAST](https://www.oclc.org/research/areas/data-science/fast.html) (Faceted Application of Subject Terminology), compatible with [OpenRefine](https://openrefine.org/) and the [W3C Reconciliation Service API v0.2](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/).

Match subject headings against 2+ million FAST authority records with full-text search.

## Features

- **Full-text search** with [FTS5](https://sqlite.org/fts5.html) for fast, fuzzy matching
- **Type filtering** by FAST facet (Topical, Personal, Geographic, etc.)
- **OpenRefine compatible** via datasette-reconcile plugin
- **Self-contained** SQLite database built in Docker, or native Python venv
- **Offline operation** - works without internet after initial setup
- **LCSH cross-references** preserved from source data

## Quick Start

### Option 1: Docker (recommended)

This directory builds the dataset (`fast.db`); serving is done by the shared
runtime container (see repo root README). The build needs ~12GB RAM available
to Docker (Docker Desktop → Settings → Resources → Memory).

```bash
# From the repo root:
make data SERVICES="fast"     # build data/fast.db (30-60 min)
make build && make up         # build + start the shared runtime

# Or standalone from this directory (writes ../../data/fast.db):
docker build --target export --output type=local,dest=../../data .
```

Endpoint: `http://127.0.0.1:8000/fast/FAST/-/reconcile`

### Option 2: Native (macOS/Linux)

```bash
make build                  # Downloads data, creates venv, builds DB
make serve                  # Start server
```

Endpoint: `http://127.0.0.1:8001/fast/FAST/-/reconcile`

### ⚠️ Cloudflare Download Issue

OCLC uses Cloudflare protection which blocks automated downloads (the build
fails within seconds if so). Download manually in your browser:

- https://researchworks.oclc.org/researchdata/fast/FASTAll.marcxml.zip (~198MB)

Then place it where your build will find it:

| Build mode | Save the zip to |
|------------|-----------------|
| Docker | `services/fast/FASTAll.marcxml.zip` (this directory; picked up automatically) |
| Native | `services/fast/data/FASTAll.marcxml.zip` |

Then re-run the build.

## Using with OpenRefine

1. Column dropdown → **Reconcile** → **Start reconciling...**
2. Click **Add Standard Service...**
3. Enter the endpoint URL (port 8000 for Docker, 8001 for native)
4. Optionally filter by type (e.g., `Topical` for subjects, `Personal` for people)

## Commands

Docker commands run from the **repo root**; native commands from this directory.
Data is exported to `data/fast.db` and served by the shared runtime —
to refresh data, re-run `make data` and restart.

| Docker (repo root) | Native | Description |
|--------------------|--------|-------------|
| `make data SERVICES="fast"` | `make build` | Build (data pipeline) |
| `make build && make up` | `make serve` | Run |
| `make down` | Ctrl+C | Stop |
| `make data SERVICES="fast"` (re-run) | `make update` | Re-download data |
| `make clean && make clean-data` | `make clean-all` | Remove everything |
| — | `make status` | Show pipeline/db stats |

## FAST Facets (Types)

Filter reconciliation by FAST facet type:

| Type | Description | Example |
|------|-------------|---------|
| `Topical` | Subjects, concepts, activities | "Climate change", "Jazz music" |
| `Personal` | People, authors, historical figures | "Shakespeare, William", "Einstein, Albert" |
| `Corporate` | Organizations, companies | "United Nations", "Apple Inc." |
| `Geographic` | Places, regions, countries | "London (England)", "Amazon River" |
| `Event` | Wars, conferences, events | "World War, 1939-1945" |
| `Chronological` | Time periods, eras | "Twentieth century" |
| `Title` | Works, publications | "Bible", "Hamlet" |
| `FormGenre` | Document types, formats | "Dictionaries", "Science fiction" |
| `Meeting` | Conferences, symposia | "Olympic Games" |

## Individual Facet Endpoints

For targeted reconciliation, use facet-specific endpoints (port 8000 for
Docker, 8001 for native):

```
http://127.0.0.1:8000/fast/FASTTopical/-/reconcile
http://127.0.0.1:8000/fast/FASTPersonal/-/reconcile
http://127.0.0.1:8000/fast/FASTGeographic/-/reconcile
http://127.0.0.1:8000/fast/FASTCorporate/-/reconcile
http://127.0.0.1:8000/fast/FASTEvent/-/reconcile
http://127.0.0.1:8000/fast/FASTChronological/-/reconcile
http://127.0.0.1:8000/fast/FASTTitle/-/reconcile
http://127.0.0.1:8000/fast/FASTFormGenre/-/reconcile
http://127.0.0.1:8000/fast/FASTMeeting/-/reconcile
```

## Pipeline

The build process transforms OCLC's MARC XML authority files:

```
OCLC FAST Data (MARC XML)
        │
        ▼  fast2skos.xsl (Saxon)
    SKOS/RDF
        │
        ▼  skos2csv-reconcile.xsl (Saxon)
    CSV (9 facet files)
        │
        ▼  sqlite-utils
    SQLite + FTS5 Index
        │
        ▼  datasette-reconcile
    W3C Reconciliation API
```

## Requirements

**Docker:** Docker Desktop (Windows, macOS, Linux)

**Native:**
- Python 3.10+
- Java JDK (for Saxon XSLT processor)
- Saxon HE (`brew install saxon` on macOS)
- curl, unzip, make

**Disk space:** ~8GB (500MB download → 2GB SKOS → 500MB CSV → 1.5GB database)

**Build time:** 30-60 minutes (Saxon transformation is CPU-intensive)

## Manual Pipeline Control

For development or debugging, run pipeline stages individually:

```bash
make download   # Get FASTAll.marcxml.zip from OCLC
make extract    # Unzip to data/marcxml/
make skos       # Convert MARC XML → SKOS (slow)
make csv        # Convert SKOS → CSV
make build      # Build SQLite database from CSV
```

## Data License

FAST data is provided by OCLC under the [ODC-BY license](https://opendatacommons.org/licenses/by/1-0/).

Credit: OCLC Research - https://www.oclc.org/research/areas/data-science/fast.html

## References

- [OCLC FAST](https://www.oclc.org/research/areas/data-science/fast.html) - Faceted Application of Subject Terminology
- [searchFAST](https://fast.oclc.org/searchfast/) - OCLC's online FAST search
- [datasette](https://datasette.io/) - Tool for exploring and publishing data
- [datasette-reconcile](https://github.com/drkane/datasette-reconcile) - Reconciliation API plugin
- [OpenRefine](https://openrefine.org/) - Data cleaning tool
- [W3C Reconciliation API](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/) - Specification

## XSLT Documentation

See `xslt/docs/` for guidelines on the MARC → SKOS transformation, including:
- ATHENA D4.2 Guidelines for mapping into SKOS
- SKOS mapping analysis notes
