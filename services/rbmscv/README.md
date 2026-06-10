# RBMS CV Dataset Builder

Builds `rbmscv.db`: the Controlled Vocabulary for Rare Materials Cataloging (RBMS CV) — ~1476 authoritative terms for bindings, genres, paper, provenance, printing/publishing evidence, and type evidence, FTS5-indexed.

- Build from repo root: `make data SERVICES="rbmscv"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Data source: https://id.loc.gov/vocabulary/rbmscv.json (Library of Congress / ACRL RBMS)
- Labels only: variant labels and sub-vocabulary facets are not in the LOC scheme download (see design doc)

Full usage and OpenRefine setup: [repo root README](../../README.md).
