# ISO 639 Dataset Builder

Builds `iso639.db`: ISO 639 language codes — parts 639-2 (LOC), 639-3 (SIL, ~7500 languages), and 639-5 (language families), deduplicated into one `languages` table with FTS5.

- Build from repo root: `make data SERVICES="isolang"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Data sources: [ISO 639-2](https://www.loc.gov/standards/iso639-2/) and [ISO 639-5](https://www.loc.gov/standards/iso639-5/) (Library of Congress), [ISO 639-3](https://iso639-3.sil.org/) (SIL International) — public standards data

Full usage, type table, and OpenRefine setup: [repo root README](../../README.md).
