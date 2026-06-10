# FAST Reconciliation Service

A local reconciliation service for [OCLC FAST](https://www.oclc.org/research/areas/data-science/fast.html) (Faceted Application of Subject Terminology), compatible with [OpenRefine](https://openrefine.org/) and the [W3C Reconciliation Service API v0.2](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/).

Match subject headings against 2+ million FAST authority records with full-text search.

## Features

- **Full-text search** with [FTS5](https://sqlite.org/fts5.html) for fast, fuzzy matching
- **Type filtering** by FAST facet (Topical, Personal, Geographic, etc.)
- **OpenRefine compatible** via datasette-reconcile plugin
- **Self-contained** Docker image with baked-in database, or native Python venv
- **Offline operation** - works without internet after initial setup
- **LCSH cross-references** preserved from source data

## Quick Start

### Option 1: Docker (recommended)

The full data pipeline runs at **image build time** — the resulting image is
self-contained (~2GB) and starts instantly. Build needs ~12GB RAM available
to Docker (Docker Desktop → Settings → Resources → Memory).

```bash
# From the repo root (compose files live in compose/):
make build SERVICES="fast" && make up SERVICES="fast"

# Or standalone from this directory:
docker build -t recon-fast .
docker run -d -p 8001:8001 recon-fast
```

### Option 2: Native (macOS/Linux)

```bash
make build                  # Downloads data, creates venv, builds DB
make serve                  # Start server
```

The service will be available at:
```
http://127.0.0.1:8001/fast/FAST/-/reconcile
```

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
3. Enter: `http://127.0.0.1:8001/fast/FAST/-/reconcile`
4. Optionally filter by type (e.g., `Topical` for subjects, `Personal` for people)

## Commands

Docker commands run from the **repo root**; native commands from this directory.
The runtime image contains only Datasette and the database (no make/Java) —
to refresh data, rebuild the image.

| Docker (repo root) | Native | Description |
|--------------------|--------|-------------|
| `make build SERVICES="fast"` | `make build` | Build (data pipeline) |
| `make up SERVICES="fast"` | `make serve` | Run |
| `make down SERVICES="fast"` | Ctrl+C | Stop |
| `make build SERVICES="fast"` (rebuild) | `make update` | Re-download data |
| `make clean SERVICES="fast"` | `make clean-all` | Remove everything |
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

For targeted reconciliation, use facet-specific endpoints:

```
http://127.0.0.1:8001/fast/FASTTopical/-/reconcile
http://127.0.0.1:8001/fast/FASTPersonal/-/reconcile
http://127.0.0.1:8001/fast/FASTGeographic/-/reconcile
http://127.0.0.1:8001/fast/FASTCorporate/-/reconcile
http://127.0.0.1:8001/fast/FASTEvent/-/reconcile
http://127.0.0.1:8001/fast/FASTChronological/-/reconcile
http://127.0.0.1:8001/fast/FASTTitle/-/reconcile
http://127.0.0.1:8001/fast/FASTFormGenre/-/reconcile
http://127.0.0.1:8001/fast/FASTMeeting/-/reconcile
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
