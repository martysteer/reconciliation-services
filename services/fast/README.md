# FAST Dataset Builder

Builds `fast.db`: [OCLC FAST](https://www.oclc.org/research/areas/data-science/fast.html) (Faceted Application of Subject Terminology) subject headings — 2M+ authority records in 9 facets. Pipeline: MARC XML → SKOS → CSV → SQLite FTS5 (Saxon XSLT).

- Build from repo root: `make data SERVICES="fast"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Source zip usually needs a manual browser download (Cloudflare) — see root README
- Requires Java + Saxon HE; XSLT notes in `xslt/docs/`
- Data source: https://researchworks.oclc.org/researchdata/fast/FASTAll.marcxml.zip
- License: [ODC-BY](https://opendatacommons.org/licenses/by/1-0/), credit OCLC Research

Full usage, requirements, facet tables, and troubleshooting: [repo root README](../../README.md).
