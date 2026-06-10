# GeoNames Dataset Builder

Builds `geonames.db`: [GeoNames](https://www.geonames.org/) geographic features — 13M+ places with FTS5 full-text search, filterable by feature class.

- Build from repo root: `make data SERVICES="geonames"`
- Standalone dev here: `make build` / `make serve` (port 8001)
- Test data: `test-data.csv` (~8000 place names incl. historical forms)
- Data source: https://download.geonames.org/export/dump/allCountries.zip
- License: [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), credit GeoNames.org

Full usage, feature-class table, and OpenRefine setup: [repo root README](../../README.md).
