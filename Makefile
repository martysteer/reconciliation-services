# Modular Reconciliation Services
#
# Usage:
#   make up                            Start all services
#   make up SERVICES="fast geonames"   Start selected services
#   make build                         Build all images (data is baked in at build time)
#   make down                          Stop all services
#   make logs SERVICES="fast"          Tail logs (all selected services together)
#   make status                        Show running services
#   make save                          Export images to dist/ for transfer (e.g. to a Pi)
#   make clean                         Stop services and remove their images
#
# All selected services run in a single compose project ("recon"), so
# logs/status/down operate on them together.

SERVICES ?= fast geonames isolang

COMPOSE_FILES := $(foreach s,$(SERVICES),-f compose/$(s).yml)
# --env-file: compose resolves the default .env against the directory of the
# first -f file (compose/), not the repo root, so pass it explicitly.
COMPOSE := docker compose -p recon $(if $(wildcard .env),--env-file .env) $(COMPOSE_FILES)

# Suppress "orphan containers" warnings when running a SERVICES subset
export COMPOSE_IGNORE_ORPHANS = 1

.PHONY: up down build logs status save clean

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

build:
	$(COMPOSE) build

logs:
	$(COMPOSE) logs -f

status:
	$(COMPOSE) ps

# Stop selected services and remove their images (fresh-build reset).
# Add `docker builder prune` manually if you also want the build cache gone.
clean:
	$(COMPOSE) down --rmi all

# Export built images as compressed tarballs for offline transfer
# (build on a workstation, copy to a Pi/server, then `docker load`)
save: SHELL := /bin/bash
save:
	@mkdir -p dist
	@set -euo pipefail; for s in $(SERVICES); do \
		echo "Saving recon-$$s:latest -> dist/recon-$$s.tar.gz"; \
		docker save "recon-$$s:latest" | gzip > "dist/recon-$$s.tar.gz"; \
	done
	@ls -lh dist/
