# ISO 15924 Dataset Builder

Builds `iso15924.db`: ISO 15924 script codes (Latn, Cyrl, Arab, ...) — 227 codes with English/French names and Unicode property value aliases, FTS5-indexed.

- Build from repo root: `make data SERVICES="iso15924"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Data source: https://unicode.org/iso15924/iso15924.txt (Unicode Consortium, ISO 15924 Registration Authority)

Full usage and OpenRefine setup: [repo root README](../../README.md).
