# Makefile for Chinese Library Classification (CLC) Reconciliation Service
#
# Datasette-based reconciliation endpoint for the Chinese Library Classification
# (中图法, 5th edition), compatible with OpenRefine's W3C Reconciliation API.
# Data sources: acdzh/GitHub (hierarchical JSON) + Wikimedia Commons (English labels).
#
# Usage:
#   make build    - Setup venv + download datasets + build database
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

SOURCE_URL_1 := https://raw.githubusercontent.com/acdzh/Chinese-Library-Classification/master/clc.json
SOURCE_URL_2 := https://commons.wikimedia.org/w/index.php?title=Module:Library_classification_navigation/CLC/CategoryTitleTable.json&action=raw
SOURCE_FILE_1 := $(DATA_DIR)/clc.json
SOURCE_FILE_2 := $(DATA_DIR)/clc-en.json
SQLITE_DB := $(DATA_DIR)/clc.db
METADATA_JSON := clc.metadata.json

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
	@echo "✓ CLC Reconciliation Service ready!"
	@echo "Start with: make serve"
	@echo "Endpoint:   http://127.0.0.1:$(PORT)/clc/classes/-/reconcile"

.PHONY: serve
serve: $(VENV_DONE) $(SQLITE_DB) $(METADATA_JSON)
	@echo "CLC Reconciliation Service"
	@echo "Endpoint: http://127.0.0.1:$(PORT)/clc/classes/-/reconcile"
	@echo "Press Ctrl+C to stop"
	@$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host $(if $(PUBLIC),0.0.0.0,127.0.0.1)

.PHONY: status
status:
	@echo "Files:"
	@if [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; else echo "  ✗ venv"; fi
	@if [ -f $(SOURCE_FILE_1) ]; then echo "  ✓ $(SOURCE_FILE_1)"; else echo "  ✗ $(SOURCE_FILE_1)"; fi
	@if [ -f $(SOURCE_FILE_2) ]; then echo "  ✓ $(SOURCE_FILE_2)"; else echo "  ✗ $(SOURCE_FILE_2)"; fi
	@if [ -f $(SQLITE_DB) ]; then echo "  ✓ $(SQLITE_DB) ($$(du -h $(SQLITE_DB) | cut -f1))"; else echo "  ✗ $(SQLITE_DB)"; fi
	@if [ -f $(SQLITE_DB) ]; then \
		sqlite3 $(SQLITE_DB) "SELECT '  Classes: ' || COUNT(*) FROM classes;"; \
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
	@$(PIP) install datasette datasette-reconcile sqlite-utils -q
	@touch $@
	@echo "✓ Virtual environment ready"

# =============================================================================
# Data Download
# =============================================================================
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(SOURCE_FILE_1): | $(DATA_DIR)
	@echo "Downloading CLC classification data from GitHub..."
	@curl -sL -o $@ "$(SOURCE_URL_1)"
	@echo "✓ Downloaded: $$(du -h $@ | cut -f1)"

$(SOURCE_FILE_2): | $(DATA_DIR)
	@echo "Downloading CLC English labels from Wikimedia Commons..."
	@curl -sL -o $@ "$(SOURCE_URL_2)"
	@echo "✓ Downloaded: $$(du -h $@ | cut -f1)"

# =============================================================================
# Database Build
# =============================================================================
$(SQLITE_DB): $(VENV_DONE) $(SOURCE_FILE_1) $(SOURCE_FILE_2) build_db.py
	@echo "Building SQLite database..."
	@rm -f $(SQLITE_DB)
	@$(PYTHON) build_db.py $(SQLITE_DB) $(SOURCE_FILE_1) $(SOURCE_FILE_2)
	@echo "Creating FTS index..."
	@$(SQLITE_UTILS) enable-fts $(SQLITE_DB) classes searchText name nameEn --fts5 --create-triggers

$(METADATA_JSON):
	@echo "ERROR: $(METADATA_JSON) not found! Restore from git."
	@exit 1

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "CLC Reconciliation Service (Chinese Library Classification)"
	@echo ""
	@echo "Commands:"
	@echo "  make build     Setup venv + download + database"
	@echo "  make serve     Start server (port $(PORT))"
	@echo "  make status    Show status"
	@echo "  make clean     Remove database"
	@echo "  make clean-all Remove everything"
	@echo ""
	@echo "Endpoint: http://127.0.0.1:$(PORT)/clc/classes/-/reconcile"
