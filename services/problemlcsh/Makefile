# Makefile for Problem LCSH Reconciliation Service
#
# Datasette-based reconciliation endpoint for problematic Library of Congress
# Subject Headings identified by the cataloging community at Cataloging Lab,
# compatible with OpenRefine's W3C Reconciliation API.
#
# Usage:
#   make build    - Setup venv + download dataset + build database
#   make serve    - Start reconciliation server
#   make status   - Show data status
#   make clean    - Remove database
#   make clean-all - Remove everything including venv

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

# =============================================================================
# Configuration
# =============================================================================
VENV_DIR := .venv
DATA_DIR := data

SOURCE_URL := https://cataloginglab.org/problem-lcsh/
SOURCE_FILE := $(DATA_DIR)/problem-lcsh.html
SQLITE_DB := $(DATA_DIR)/problemlcsh.db
METADATA_JSON := problemlcsh.metadata.json

PORT ?= 8001

PYTHON := $(VENV_DIR)/bin/python3
PIP := $(VENV_DIR)/bin/pip
DATASETTE := $(VENV_DIR)/bin/datasette
SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
VENV_DONE := $(VENV_DIR)/.done

# =============================================================================
# Main Targets
# =============================================================================
.PHONY: build
build: $(VENV_DONE) $(SQLITE_DB)
	@echo ""
	@echo "✓ Problem LCSH Reconciliation Service ready!"
	@echo "Start with: make serve"
	@echo "Endpoint:   http://127.0.0.1:$(PORT)/problemlcsh/headings/-/reconcile"

.PHONY: serve
serve: $(VENV_DONE) $(SQLITE_DB) $(METADATA_JSON)
	@echo "Problem LCSH Reconciliation Service"
	@echo "Endpoint: http://127.0.0.1:$(PORT)/problemlcsh/headings/-/reconcile"
	@echo "Press Ctrl+C to stop"
	@$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host $(if $(PUBLIC),0.0.0.0,127.0.0.1)

.PHONY: status
status:
	@echo "Files:"
	@if [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
	@if [ -f $(SOURCE_FILE) ]; then echo "  ✓ $(SOURCE_FILE)"; else echo "  ✗ $(SOURCE_FILE)"; fi
	@if [ -f $(SQLITE_DB) ]; then echo "  ✓ $(SQLITE_DB) ($$(du -h $(SQLITE_DB) | cut -f1))"; else echo "  ✗ $(SQLITE_DB)"; fi
	@if [ -f $(SQLITE_DB) ]; then \
		sqlite3 $(SQLITE_DB) "SELECT '  Headings: ' || COUNT(*) FROM headings;"; \
	fi

.PHONY: clean
clean:
	@rm -f $(SQLITE_DB)
	@echo "✓ Database removed"

.PHONY: clean-all
clean-all:
	@rm -rf $(DATA_DIR) $(VENV_DIR)
	@echo "✓ All files removed"

# =============================================================================
# Virtual Environment
# =============================================================================
$(VENV_DIR)/.done:
	@echo "Setting up Python virtual environment..."
	@python3 -m venv $(VENV_DIR)
	@$(PIP) install --upgrade pip -q
	@$(PIP) install datasette datasette-reconcile sqlite-utils beautifulsoup4 -q
	@touch $@
	@echo "✓ Virtual environment ready"

# =============================================================================
# Data Download
# =============================================================================
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(SOURCE_FILE): | $(DATA_DIR)
	@echo "Downloading Problem LCSH page from Cataloging Lab..."
	@curl -sL -o $@ "$(SOURCE_URL)"
	@echo "✓ Downloaded: $$(du -h $@ | cut -f1)"

# =============================================================================
# Database Build
# =============================================================================
$(SQLITE_DB): $(VENV_DONE) $(SOURCE_FILE) build_db.py
	@echo "Building SQLite database..."
	@rm -f $(SQLITE_DB)
	@$(PYTHON) build_db.py $(SQLITE_DB) $(SOURCE_FILE)
	@echo "Creating FTS index..."
	@$(SQLITE_UTILS) enable-fts $(SQLITE_DB) headings searchText name --fts5 --create-triggers

$(METADATA_JSON):
	@echo "ERROR: $(METADATA_JSON) not found! Restore from git."
	@exit 1

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "Problem LCSH Reconciliation Service"
	@echo ""
	@echo "Commands:"
	@echo "  make build     Setup venv + download + database"
	@echo "  make serve     Start server (port $(PORT))"
	@echo "  make status    Show status"
	@echo "  make clean     Remove database"
	@echo "  make clean-all Remove everything"
	@echo ""
	@echo "Endpoint: http://127.0.0.1:$(PORT)/problemlcsh/headings/-/reconcile"
