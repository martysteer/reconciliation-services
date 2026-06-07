# Modular Reconciliation Services
#
# Usage:
#   make up                            Start all services
#   make up SERVICES="fast geonames"   Start selected services
#   make build                         Build all images
#   make down                          Stop all services
#   make logs                          Tail logs
#   make status                        Show running services

SERVICES ?= fast geonames isolang

COMPOSE_FILES := $(foreach s,$(SERVICES),-f compose/$(s).yml)

.PHONY: up down build logs status

up:
	docker compose $(COMPOSE_FILES) up -d

down:
	docker compose $(COMPOSE_FILES) down

build:
	docker compose $(COMPOSE_FILES) build

logs:
	docker compose $(COMPOSE_FILES) logs -f

status:
	docker compose $(COMPOSE_FILES) ps
