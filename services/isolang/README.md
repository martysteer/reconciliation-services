# ISO 639 Language Code Reconciliation Service

Datasette-based reconciliation service for ISO 639 language codes, compatible with OpenRefine's W3C Reconciliation API.

## Quick Start

### Option 1: Docker

The data pipeline runs at **image build time** (< 2 min) — the resulting
image is self-contained (~200MB) and starts instantly.

```bash
# From the repo root (compose files live in compose/):
make build SERVICES="isolang" && make up SERVICES="isolang"

# Or standalone from this directory:
docker build -t recon-isolang .
docker run -d -p 8003:8001 recon-isolang
```

Endpoint: `http://127.0.0.1:8003/iso639/languages/-/reconcile`

### Option 2: Native (macOS/Linux)

```bash
make build   # Setup venv + download all datasets + build database
make serve   # Start server on port 8001
```

Endpoint: `http://127.0.0.1:8001/iso639/languages/-/reconcile`

## Single Endpoint with Type Filtering

**Endpoint:** `/iso639/languages/-/reconcile` (port 8003 for Docker, 8001 for native)

Filter by type when reconciling:
- **ISO 639-2** — Individual languages (~500 codes, Library of Congress)
- **ISO 639-3** — All known languages (~7500 codes, SIL International)
- **ISO 639-5** — Language families/groups (~50 unique codes, Library of Congress)

> **Note:** Codes are unique across the database. If a code exists in multiple ISO 639 parts (e.g., `eng` in both 639-2 and 639-3), it appears once with the type from the first standard that defined it (639-2 takes precedence).

## ISO 639 Standard Overview

| Part | Description | Authority |
|------|-------------|-----------|
| **639-1** | 2-letter codes (~184 major languages) | Infoterm |
| **639-2** | 3-letter codes (languages + collections) | Library of Congress |
| **639-3** | 3-letter codes (ALL known languages) | SIL International |
| **639-4** | Implementation guidelines (no codes) | — |
| **639-5** | 3-letter codes (language families) | Library of Congress |

## OpenRefine Usage

1. Start the service (`make up SERVICES="isolang"` from repo root, or `make serve`)
2. In OpenRefine: Column → Reconcile → Start reconciling...
3. Add Standard Service: the endpoint URL above
4. Optionally filter by type (ISO 639-2, ISO 639-3, or ISO 639-5)

## Data Sources

All data is downloaded from authoritative sources:

| Source | URL |
|--------|-----|
| ISO 639-2 | `loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt` |
| ISO 639-3 | `iso639-3.sil.org/.../iso-639-3.tab` |
| ISO 639-5 | `id.loc.gov/vocabulary/iso639-5.tsv` |

## Commands

Docker commands run from the **repo root**; native commands from this directory.
Data is baked into the image at build time — to refresh data, rebuild the image.

| Docker (repo root) | Native | Description |
|--------------------|--------|-------------|
| `make build SERVICES="isolang"` | `make build` | Build (download datasets, build SQLite + FTS) |
| `make up SERVICES="isolang"` | `make serve` | Run |
| `make down SERVICES="isolang"` | Ctrl+C | Stop |
| `make clean SERVICES="isolang"` | `make clean-all` | Remove everything |
| — | `make status` | Show data status |
| — | `make clean` | Remove database only |

## Database Schema

The `languages` table contains:

| Column | Description |
|--------|-------------|
| `id` | ISO 639 code (primary key) |
| `name` | Language name (English) |
| `type` | ISO 639-2, ISO 639-3, or ISO 639-5 |
| `alpha2` | 2-letter code (if available) |
| `alpha3` | 3-letter code |
| `scope` | Individual, Macrolanguage, Special (639-3 only) |
| `language_type` | Living, Extinct, Ancient, etc. (639-3 only) |
| `name_french` | French name |
| `searchText` | Full-text search field |

## Files

```
services/isolang/
├── Dockerfile
├── Makefile
├── README.md
├── build_db.py              # Database builder script
├── iso639.metadata.json     # Datasette config
└── data/                    # (gitignored)
    ├── iso639-2.txt         # LOC source
    ├── iso639-3.tab         # SIL source
    ├── iso639-5.tsv         # LOC Linked Data
    └── iso639.db            # SQLite + FTS
```

## References

- [ISO 639 Language Code (ISO)](https://www.iso.org/iso-639-language-code)
- [ISO 639-2 (LOC)](https://www.loc.gov/standards/iso639-2/)
- [ISO 639-3 (SIL)](https://iso639-3.sil.org/)
- [ISO 639-5 (LOC)](https://www.loc.gov/standards/iso639-5/)
