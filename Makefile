# Modular Reconciliation Services
#
# Usage:
#   make up                            Start all services
#   make up SERVICES="fast geonames"   Start selected services
#   make build                         Build all images
#   make down                          Stop all services
#   make logs SERVICES="fast"          Tail one service's logs
#   make status                        Show running services

SERVICES ?= fast geonames isolang

.PHONY: up down build logs status

up:
	@$(foreach s,$(SERVICES),docker compose -f compose/$(s).yml up -d;)

down:
	@$(foreach s,$(SERVICES),docker compose -f compose/$(s).yml down;)

build:
	@$(foreach s,$(SERVICES),docker compose -f compose/$(s).yml build;)

logs:
	@$(foreach s,$(SERVICES),docker compose -f compose/$(s).yml logs -f;)

status:
	@$(foreach s,$(SERVICES),docker compose -f compose/$(s).yml ps;)
