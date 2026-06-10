# Reconciliation Services -- native dataset builds + single Datasette runtime
#
# Usage:
#   make data                          Build all dataset .db files into data/
#   make data SERVICES="isolang"       Build selected datasets only
#   make build                         Build the runtime image
#   make up / down                     Start / stop the runtime
#   make logs / status                 Inspect the runtime
#   make save                          Export runtime image to dist/ for transfer
#   make clean                         Stop runtime and remove its image
#   make clean-data                    Remove built .db files
#
# Datasets are built NATIVELY (no Docker) by each service's own Makefile,
# then copied into data/ for the runtime to serve. See README for host
# requirements (FAST needs Java + Saxon).
#
# Deploying elsewhere (e.g. Raspberry Pi): `make data && make build && make save`
# on a workstation, copy dist/recon-runtime.tar.gz + data/*.db to the target,
# `docker load`, then `make up` from a checkout of this repo. The .db files
# are architecture-independent; only the (small) runtime image is per-arch.

SERVICES ?= fast geonames isolang iso15924 rbmscv

# Compose resolves the default .env against the compose file directory,
# not the repo root, so pass it explicitly.
COMPOSE := docker compose -p recon $(if $(wildcard .env),--env-file .env) -f compose/recon.yml

.PHONY: data data-fast data-geonames data-isolang data-iso15924 data-rbmscv \
        build up down logs status save clean clean-data

# Each dataset builds natively in its own directory (incremental: each
# service's Makefile skips completed downloads/stages), then the .db is
# copied to data/ for the runtime.
data: $(addprefix data-,$(SERVICES))
	@ls -lh data/*.db

data-fast:
	$(MAKE) -C services/fast build
	@mkdir -p data
	cp services/fast/data/fast.db data/fast.db

data-geonames:
	$(MAKE) -C services/geonames build
	@mkdir -p data
	cp services/geonames/geonames.db data/geonames.db

data-isolang:
	$(MAKE) -C services/isolang build
	@mkdir -p data
	cp services/isolang/data/iso639.db data/iso639.db

data-iso15924:
	$(MAKE) -C services/iso15924 build
	@mkdir -p data
	cp services/iso15924/data/iso15924.db data/iso15924.db

data-rbmscv:
	$(MAKE) -C services/rbmscv build
	@mkdir -p data
	cp services/rbmscv/data/rbmscv.db data/rbmscv.db

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

# Export the runtime image for offline transfer. Dataset .db files are
# transferred as plain files (scp data/*.db ...), not inside images.
save: SHELL := /bin/bash
save:
	@mkdir -p dist
	@set -euo pipefail; \
	echo "Saving recon-runtime:latest -> dist/recon-runtime.tar.gz"; \
	docker save recon-runtime:latest | gzip > dist/recon-runtime.tar.gz
	@ls -lh dist/

clean:
	$(COMPOSE) down --rmi all

clean-data:
	rm -f data/*.db
