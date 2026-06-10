# ISO 15924 + RBMS CV Reconciliation Services — Design

Two new datasets for the reconciliation runtime, following the established
isolang pattern: native Makefile build → SQLite + FTS5 → served by the shared
Datasette runtime container.

## Goals

- Reconcile script names against ISO 15924 script codes (e.g. "Latin" → `Latn`)
- Reconcile rare-materials cataloging terms against the RBMS Controlled
  Vocabulary (e.g. "Funeral books" → `cv01389`)
- Zero runtime changes: drop-in via the metadata merge; one image rebuild

## Non-Goals (deferred)

- RBMS variant/alternate labels and sub-vocabulary facet filtering (Binding,
  Genre, Paper, Provenance...). The scheme-level LOC downloads don't contain
  them; would need bulk MADS parsing. User chose labels-only; extend later if
  matching quality demands it.
- RBMS broader/narrower hierarchy — present in source, no reconciliation value.
- Type filtering for either dataset (scripts are one kind; RBMS terms are all
  `GenreForm` in the source).

## Data Sources (verified 2026-06-10)

| Dataset | URL | Format | Size / rows |
|---------|-----|--------|-------------|
| ISO 15924 | `https://unicode.org/iso15924/iso15924.txt` | semicolon-delimited, `#` comments | 227 codes |
| RBMS CV | `https://id.loc.gov/vocabulary/rbmscv.json` | JSON-LD array (scheme + members) | ~1476 terms, 438KB |

Notes from source inspection:
- iso15924.txt fields: `Code;N°;English Name;Nom français;PVA;Unicode Version;Date`.
  Some fields empty (PVA, Unicode version). File has a UTF-8 header comment block.
- rbmscv.json is a flat JSON-LD list. Term entries have `@id`
  (`http://id.loc.gov/vocabulary/rbmscv/cvNNNNN`), `@type`
  (`madsrdf#GenreForm`), and `madsrdf#authoritativeLabel` (values sometimes
  duplicated — dedupe). Non-term entries (MADSScheme, RecordInfo, xhtml
  fragments) must be skipped: keep only entries whose `@id` starts with the
  term prefix AND have an authoritativeLabel.
- The `.tsv` URL for rbmscv lies: serves RDF/XML. Do not use.
- ISO 15924 registration authority is the Unicode Consortium. RBMS CV is
  published by LOC id.loc.gov on behalf of ACRL/RBMS.

## Architecture

Exact isolang twins — one directory per dataset:

```
services/iso15924/              services/rbmscv/
├── Makefile                    ├── Makefile
├── build_db.py                 ├── build_db.py
├── iso15924.metadata.json      ├── rbmscv.metadata.json
└── README.md (stub)            └── README.md (stub)
```

Each Makefile: venv setup (datasette, datasette-reconcile, sqlite-utils) +
curl download to `data/` + `build_db.py` (stdlib `sqlite3`) + `sqlite-utils
enable-fts ... --fts5 --create-triggers`. Targets: `build`, `serve` (port
8001), `status`, `clean`, `clean-all` — matching isolang.

Rejected alternatives:
- Adding tables to the isolang service — mixes unrelated URL namespaces.
- A shared "small vocabularies" builder — premature abstraction for two
  ~100-line services.

## Database Schemas

### `iso15924.db`, table `scripts` (227 rows)

| Column | Source | Example |
|--------|--------|---------|
| `id` | 4-letter code (PK) | `Latn` |
| `name` | English name | `Latin` |
| `code_num` | numeric code | `215` |
| `name_french` | French name | `latin` |
| `pva` | Property Value Alias (may be empty) | `Latin` |
| `unicode_version` | (may be empty) | `1.1` |
| `date` | registration date | `2004-05-01` |
| `searchText` | name + french + pva + code | |

FTS5 on `searchText`, `name`.

### `rbmscv.db`, table `terms` (~1476 rows)

| Column | Source | Example |
|--------|--------|---------|
| `id` | URI tail (PK) | `cv01389` |
| `uri` | full URI | `http://id.loc.gov/vocabulary/rbmscv/cv01389` |
| `name` | authoritative label (deduped) | `Funeral books` |
| `searchText` | name | |

FTS5 on `searchText`, `name`.

## Endpoints

| Dataset | Endpoint |
|---------|----------|
| ISO 15924 | `/iso15924/scripts/-/reconcile` |
| RBMS CV | `/rbmscv/terms/-/reconcile` |

Metadata (merged into the runtime at image build, like existing services):
- iso15924: `id_field: id`, `name_field: name`, fts table `scripts_fts`;
  no `type_field`; attribution to Unicode/ISO 15924-RA
- rbmscv: `id_field: id`, `name_field: name`, fts table `terms_fts`;
  no `type_field`; `view_url: http://id.loc.gov/vocabulary/rbmscv/{{id}}`;
  identifierSpace `http://id.loc.gov/vocabulary/rbmscv/`

## Repo Integration

- Root `Makefile`: `SERVICES ?= fast geonames isolang iso15924 rbmscv`;
  new `data-iso15924` and `data-rbmscv` targets (build + copy
  `services/<s>/data/<s>.db` → `data/<s>.db`)
- Root `README.md`: endpoint rows, build-table rows (both "< 1 min", ~100KB-1MB,
  licenses), references
- Runtime: untouched code; `make build` once so the merged metadata picks up
  the two new files
- Per-service stub READMEs, matching existing stubs

## Error Handling

- Downloads: plain `curl -sL`; build fails loudly if file missing/empty
  (build_db.py exits non-zero on zero parsed rows — guards against silently
  shipping an empty database if a source moves or serves an error page)
- rbmscv parsing: skip entries without term-prefix `@id` or without label;
  count check at end

## Testing / Verification

- `make data SERVICES="iso15924 rbmscv"` builds both natively
- Runtime restart + curl checks:
  - `/iso15924/scripts/-/reconcile` query "Latin" → `Latn` score 100
  - `/rbmscv/terms/-/reconcile` query "Funeral books" → `cv01389` score 100
- Existing endpoints (iso639, geonames) still serve

## Licenses / Attribution

- ISO 15924: code table from the Unicode Consortium (ISO 15924 Registration
  Authority), freely available data
- RBMS CV: Library of Congress id.loc.gov / ACRL Rare Books and Manuscripts
  Section
