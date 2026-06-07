# ISO 639 Language Code Reconciliation Service

Datasette-based reconciliation service for ISO 639 language codes, compatible with OpenRefine's W3C Reconciliation API.

## Quick Start

```bash
make build   # Setup venv + download all datasets + build database
make serve   # Start server on port 8001
```

## Single Endpoint with Type Filtering

**Endpoint:** `http://127.0.0.1:8001/iso639/languages/-/reconcile`

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

1. Start the service: `make serve`
2. In OpenRefine: Column → Reconcile → Start reconciling...
3. Add Standard Service: `http://127.0.0.1:8001/iso639/languages/-/reconcile`
4. Optionally filter by type (ISO 639-2, ISO 639-3, or ISO 639-5)

## Data Sources

All data is downloaded from authoritative sources:

| Source | URL |
|--------|-----|
| ISO 639-2 | `loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt` |
| ISO 639-3 | `iso639-3.sil.org/.../iso-639-3.tab` |
| ISO 639-5 | `id.loc.gov/vocabulary/iso639-5.tsv` |

## Commands

| Command | Description |
|---------|-------------|
| `make build` | Setup venv, download datasets, build SQLite + FTS |
| `make serve` | Start datasette reconciliation server |
| `make status` | Show data status |
| `make clean` | Remove database |
| `make clean-all` | Remove everything including venv |

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
isolang-reconciliation/
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
