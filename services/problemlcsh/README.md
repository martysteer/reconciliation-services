# Problem LCSH Dataset Builder

Builds `problemlcsh.db`: ~110 problematic Library of Congress Subject Headings identified by the cataloging community, with preferred alternatives and explanatory comments, FTS5-indexed.

- Build from repo root: `make data SERVICES="problemlcsh"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Data source: https://cataloginglab.org/problem-lcsh/ (Cataloging Lab, CC BY-NC-SA 4.0)
- Duplicate heading names (e.g. different takes on the same LCSH) are kept as separate rows — both appear in reconciliation results

Full usage and OpenRefine setup: [repo root README](../../README.md).
