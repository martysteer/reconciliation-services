# Reconciliation Services -- per-dataset builders + single Datasette runtime
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
# Deploying elsewhere (e.g. Raspberry Pi): `make data && make build && make save`
# on a workstation, copy dist/recon-runtime.tar.gz + data/*.db to the target,
# `docker load`, then `make up` from a checkout of this repo. The .db files
# are architecture-independent; only the (small) runtime image is per-arch.

SERVICES ?= fast geonames isolang

# Compose resolves the default .env against the compose file directory,
# not the repo root, so pass it explicitly.
COMPOSE := docker compose -p recon $(if $(wildcard .env),--env-file .env) -f compose/recon.yml

.PHONY: data build up down logs status save clean clean-data

# Build each dataset's .db via its builder image and export it to data/.
# BuildKit caches the pipeline layers, so unchanged datasets re-export fast.
data:
	@mkdir -p data
	@for s in $(SERVICES); do \
		echo "==> Building dataset: $$s"; \
		docker build --target export --output type=local,dest=data "services/$$s" || exit 1; \
	done
	@ls -lh data/*.db

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
