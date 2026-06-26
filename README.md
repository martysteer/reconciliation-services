# Reconciliation Services

W3C Reconciliation Service API endpoints for OpenRefine. One Datasette container serves every dataset on a single port; each dataset is built **natively** by its own Makefile into an SQLite file in `data/`. Docker is used only for the thin runtime.

## Endpoints

All on one port (default 8000):

| Dataset | Endpoint |
|---------|----------|
| OCLC FAST subject headings | [`/fast/FAST/-/reconcile`](http://127.0.0.1:8000/fast/FAST/-/reconcile) (+ per-facet endpoints below) |
| GeoNames geographic features | [`/geonames/geonames/-/reconcile`](http://127.0.0.1:8000/geonames/geonames/-/reconcile) |
| ISO 639 language codes | [`/iso639/languages/-/reconcile`](http://127.0.0.1:8000/iso639/languages/-/reconcile) |
| ISO 15924 script codes | [`/iso15924/scripts/-/reconcile`](http://127.0.0.1:8000/iso15924/scripts/-/reconcile) |
| RBMS Controlled Vocabulary | [`/rbmscv/terms/-/reconcile`](http://127.0.0.1:8000/rbmscv/terms/-/reconcile) |
| Problem LCSH | [`/problemlcsh/headings/-/reconcile`](http://127.0.0.1:8000/problemlcsh/headings/-/reconcile) |

Links assume the default port (8000) on localhost.

## Quick Start

```bash
make data        # Build all dataset .db files into data/ (native; see Requirements)
make build       # Build the runtime image
make up          # Start serving on http://127.0.0.1:8000/
```

## Usage

```bash
make data                            # Build all dataset databases (native)
make data SERVICES="isolang"         # Build one dataset
make build                           # Build the runtime image
make up / make down                  # Start / stop
make logs / make status              # Inspect
make save                            # Export runtime image to dist/
make clean                           # Stop + remove runtime image
make clean-data                      # Remove built .db files from data/
```

Refreshing one dataset: `make data SERVICES="geonames" && make down && make up`.
No image rebuild needed — the runtime picks up whatever `.db` files are in `data/`.

Datasets build incrementally: each service's Makefile skips downloads and pipeline stages that are already done. `make -C services/<name> clean` removes only that service's local `.db`; `clean-all` removes downloads and venv too.

## Build Requirements (native)

All datasets: macOS or Linux with `python3` (3.10+), `curl`, `unzip`, `sqlite3`, `make`. Each service creates its own Python venv automatically.

**FAST additionally:** Java JDK + Saxon HE (`brew install saxon` on macOS; the build checks and offers to install). The XSLT step runs `java -Xmx8g` — 12-16GB host RAM recommended.

| Dataset | Build Time | .db Size | Data Source | License |
|---------|-----------|----------|-------------|---------|
| isolang | < 2 min | ~3MB | LOC, SIL International | public standards data |
| iso15924 | < 1 min | < 1MB | Unicode Consortium | freely available data |
| rbmscv | < 1 min | < 1MB | LOC id.loc.gov / ACRL RBMS | public domain |
| problemlcsh | < 1 min | < 1MB | Cataloging Lab | CC BY-NC-SA 4.0 |
| geonames | ~12 min | ~4GB | GeoNames.org | CC BY 4.0 |
| fast | 30-60 min | ~1.5GB | OCLC FAST | ODC-BY |

Disk: intermediates stay in each service directory (geonames ~2GB downloads, fast ~8GB zip/MARC/SKOS/CSV); the final `.db` is *copied* to `data/`, so it exists twice while service-side copies are kept.

### FAST: manual download if required (Cloudflare)

OCLC sometimes blocks automated downloads (the build fails within seconds if so). Download in a browser:

- https://researchworks.oclc.org/researchdata/fast/FASTAll.marcxml.zip (~198MB)

Save it to `services/fast/data/FASTAll.marcxml.zip`, then re-run `make data SERVICES="fast"`.

## Using with OpenRefine

1. Start the service (`make up`)
2. Column dropdown → **Reconcile** → **Start reconciling...**
3. Click **Add Standard Service...** and enter an endpoint URL from the table above (e.g. `http://127.0.0.1:8000/fast/FAST/-/reconcile`)
4. Optionally filter by type (tables below)

Sample data for testing: `services/geonames/test-data.csv` (~8000 place names including historical forms — Batavia→Jakarta, Canton→Guangzhou).

## Type Filtering

### FAST facets

| Type | Description | Example |
|------|-------------|---------|
| `Topical` | Subjects, concepts, activities | "Climate change", "Jazz music" |
| `Personal` | People, authors, historical figures | "Shakespeare, William" |
| `Corporate` | Organizations, companies | "United Nations" |
| `Geographic` | Places, regions, countries | "London (England)" |
| `Event` | Wars, conferences, events | "World War, 1939-1945" |
| `Chronological` | Time periods, eras | "Twentieth century" |
| `Title` | Works, publications | "Hamlet" |
| `FormGenre` | Document types, formats | "Dictionaries" |
| `Meeting` | Conferences, symposia | "Olympic Games" |

Facet-specific endpoints also exist for targeted reconciliation:
[`/fast/FASTTopical/-/reconcile`](http://127.0.0.1:8000/fast/FASTTopical/-/reconcile), [`/fast/FASTPersonal/-/reconcile`](http://127.0.0.1:8000/fast/FASTPersonal/-/reconcile), [`/fast/FASTGeographic/-/reconcile`](http://127.0.0.1:8000/fast/FASTGeographic/-/reconcile), [`/fast/FASTCorporate/-/reconcile`](http://127.0.0.1:8000/fast/FASTCorporate/-/reconcile), [`/fast/FASTEvent/-/reconcile`](http://127.0.0.1:8000/fast/FASTEvent/-/reconcile), [`/fast/FASTChronological/-/reconcile`](http://127.0.0.1:8000/fast/FASTChronological/-/reconcile), [`/fast/FASTTitle/-/reconcile`](http://127.0.0.1:8000/fast/FASTTitle/-/reconcile), [`/fast/FASTFormGenre/-/reconcile`](http://127.0.0.1:8000/fast/FASTFormGenre/-/reconcile), [`/fast/FASTMeeting/-/reconcile`](http://127.0.0.1:8000/fast/FASTMeeting/-/reconcile)

### GeoNames feature classes

| Type | Description |
|------|-------------|
| `P` | Populated places (cities, towns, villages) |
| `A` | Administrative divisions (countries, states) |
| `H` | Hydrographic (rivers, lakes, seas) |
| `T` | Terrain (mountains, valleys, islands) |
| `L` | Areas (parks, reserves, regions) |
| `S` | Structures (buildings, airports) |
| `R` | Roads/railroads |
| `V` | Vegetation (forests, grasslands) |
| `U` | Undersea features |

### ISO 639 parts

| Type | Description | Authority |
|------|-------------|-----------|
| `ISO 639-2` | Individual languages (~500 codes) | Library of Congress |
| `ISO 639-3` | All known languages (~7500 codes) | SIL International |
| `ISO 639-5` | Language families/groups (~115 codes) | Library of Congress |

Codes are unique across the database: if a code exists in multiple parts (e.g. `eng`), it appears once with the type from the first standard that defined it (639-2 takes precedence).

## Developing a Single Dataset

Each service directory is self-contained for development:

```bash
cd services/<name>
make build     # venv + download + build (incremental)
make serve     # standalone Datasette on port 8001 (PUBLIC=1 for network access)
make status    # pipeline/db stats
make test      # FTS + endpoint smoke test (fast, geonames)
make clean     # remove local .db only
make clean-all # remove everything incl. downloads and venv
```

FAST pipeline stages can be run individually for debugging: `make download`, `make extract`, `make skos`, `make csv`, `make build`. The pipeline is MARC XML → SKOS (`xslt/fast2skos.xsl`) → CSV (`xslt/skos2csv-reconcile.xsl`) → SQLite + FTS5; see `services/fast/xslt/docs/` for transformation notes.

## Configuration

Copy `.env.example` to `.env` to customize the port (default `RECON_PORT=8000`):

```bash
cp .env.example .env
```

## Deploying to a Pi / Server (build on laptop, copy artifacts)

The Pi 5 (8GB) cannot build the FAST or GeoNames datasets itself. Build on
a workstation and copy across — no registry needed.

**1. On the laptop — build and export:**

```bash
make data && make build && make save
```

**2. Copy to the target machine:**

```bash
scp dist/recon-runtime.tar.gz data/*.db pi@raspberrypi.local:~
```

**3. On the Pi — load and run (from a checkout of this repo):**

```bash
docker load < ~/recon-runtime.tar.gz
mkdir -p data && mv ~/*.db data/
make up
```

The `.db` files are architecture-independent — only the small runtime image
is per-arch. An Apple Silicon Mac builds `arm64` natively, correct for Pi 5;
for an `amd64` server, cross-build with:

```bash
docker buildx build --platform linux/amd64 --load -t recon-runtime:latest -f services/runtime/Dockerfile .
```

Refreshing one dataset later: rebuild just that `.db` on the workstation,
scp it across, restart (`make down && make up`) — no image transfer needed.

## Adding a Dataset

1. Create `services/<name>/` with a Makefile whose `build` target produces
   the dataset's `.db` (plus a `serve` target for standalone dev, by convention)
2. Add `services/<name>/<name>.metadata.json` with a `databases` section
   (see existing services; the runtime merges all of them at image build)
3. Add a `data-<name>` target to the root Makefile (build + copy the `.db`
   to `data/`) and add `<name>` to `SERVICES`
4. `make data SERVICES="<name>" && make build && make down && make up`
5. Update this README

## Data Licenses

- **FAST:** OCLC Research, [ODC-BY](https://opendatacommons.org/licenses/by/1-0/) — https://www.oclc.org/research/areas/data-science/fast.html
- **GeoNames:** [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — https://www.geonames.org/
- **ISO 639:** Library of Congress and SIL International standards data
- **ISO 15924:** Unicode Consortium (ISO 15924 Registration Authority), freely available data — https://unicode.org/iso15924/
- **RBMS CV:** Library of Congress / ACRL Rare Books and Manuscripts Section — https://id.loc.gov/vocabulary/rbmscv.html
- **Problem LCSH:** Cataloging Lab, [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) — https://cataloginglab.org/problem-lcsh/

## References

- [W3C Reconciliation API](https://www.w3.org/community/reports/reconciliation/CG-FINAL-specs-0.2-20230410/) - Specification
- [OpenRefine reconciliation docs](https://docs.openrefine.org/manual/reconciling)
- [Datasette](https://datasette.io/) + [datasette-reconcile](https://github.com/drkane/datasette-reconcile)
- [SQLite FTS5](https://sqlite.org/fts5.html)
- [OCLC searchFAST](https://fast.oclc.org/searchfast/)
- [ISO 639](https://www.iso.org/iso-639-language-code) / [ISO 639-2 (LOC)](https://www.loc.gov/standards/iso639-2/) / [ISO 639-3 (SIL)](https://iso639-3.sil.org/) / [ISO 639-5 (LOC)](https://www.loc.gov/standards/iso639-5/)
- [ISO 15924 (Unicode)](https://unicode.org/iso15924/) / [RBMS CV (LOC)](https://id.loc.gov/vocabulary/rbmscv.html) / [Problem LCSH (Cataloging Lab)](https://cataloginglab.org/problem-lcsh/)
