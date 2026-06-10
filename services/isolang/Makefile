# Makefile for ISO 639 Language Code Reconciliation Service
#
# Datasette-based reconciliation endpoint for ISO 639 language codes
# Compatible with OpenRefine's W3C Reconciliation API
#
# Single endpoint with types:
#   - ISO 639-2: ~500 codes (LOC) - individual languages + collections
#   - ISO 639-3: ~8000 codes (SIL) - ALL known languages
#   - ISO 639-5: ~115 codes (LOC) - language families/groups
#
# Usage:
#   make build    - Setup venv + download all datasets + build database
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

ISO639_2_URL := https://www.loc.gov/standards/iso639-2/ISO-639-2_utf-8.txt
ISO639_3_URL := https://iso639-3.sil.org/sites/iso639-3/files/downloads/iso-639-3.tab
ISO639_5_URL := https://id.loc.gov/vocabulary/iso639-5.tsv

ISO639_2_FILE := $(DATA_DIR)/iso639-2.txt
ISO639_3_FILE := $(DATA_DIR)/iso639-3.tab
ISO639_5_FILE := $(DATA_DIR)/iso639-5.tsv
SQLITE_DB := $(DATA_DIR)/iso639.db
METADATA_JSON := iso639.metadata.json

PORT ?= 8001

# Docker mode: when DOCKER=1, skip venv and use system Python
DOCKER ?=

ifdef DOCKER
  PYTHON := python3
  PIP := pip
  DATASETTE := datasette
  SQLITE_UTILS := sqlite-utils
  VENV_DONE :=
else
  PYTHON := $(VENV_DIR)/bin/python3
  PIP := $(VENV_DIR)/bin/pip
  DATASETTE := $(VENV_DIR)/bin/datasette
  SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
  VENV_DONE := $(VENV_DIR)/.done
endif

# =============================================================================
# Main Targets
# =============================================================================
.PHONY: build
build: $(VENV_DONE) $(SQLITE_DB)
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "✓ ISO 639 Reconciliation Service ready!"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Records by type:"
	@sqlite3 $(SQLITE_DB) "SELECT '  ' || type || ': ' || COUNT(*) FROM languages GROUP BY type ORDER BY type;"
	@echo ""
	@echo "Start with: make serve"
	@echo "Endpoint:   http://127.0.0.1:$(PORT)/iso639/languages/-/reconcile"

.PHONY: serve
serve: $(VENV_DONE) $(SQLITE_DB) $(METADATA_JSON)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "ISO 639 Language Code Reconciliation Service"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Endpoint: http://127.0.0.1:$(PORT)/iso639/languages/-/reconcile"
	@echo ""
	@echo "Types available for filtering:"
	@echo "  - ISO 639-2  (individual languages, ~500 codes)"
	@echo "  - ISO 639-3  (all known languages, ~8000 codes)"
	@echo "  - ISO 639-5  (language families, ~115 codes)"
	@echo ""
	@echo "Press Ctrl+C to stop"
	@echo "═══════════════════════════════════════════════════════════════"
	@$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host $(if $(PUBLIC),0.0.0.0,127.0.0.1)

.PHONY: status
status:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "ISO 639 Service Status"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Files:"
	@if [ -n "$(VENV_DONE)" ] && [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; elif [ -z "$(VENV_DONE)" ]; then echo "  ✓ system (Docker)"; else echo "  ✗ venv"; fi
	@if [ -f $(ISO639_2_FILE) ]; then echo "  ✓ $(ISO639_2_FILE)"; else echo "  ✗ $(ISO639_2_FILE)"; fi
	@if [ -f $(ISO639_3_FILE) ]; then echo "  ✓ $(ISO639_3_FILE)"; else echo "  ✗ $(ISO639_3_FILE)"; fi
	@if [ -f $(ISO639_5_FILE) ]; then echo "  ✓ $(ISO639_5_FILE)"; else echo "  ✗ $(ISO639_5_FILE)"; fi
	@if [ -f $(SQLITE_DB) ]; then \
		echo "  ✓ $(SQLITE_DB) ($$(du -h $(SQLITE_DB) | cut -f1))"; \
	else echo "  ✗ $(SQLITE_DB)"; fi
	@echo ""
	@if [ -f $(SQLITE_DB) ]; then \
		echo "Database:"; \
		sqlite3 $(SQLITE_DB) "SELECT '  ' || type || ': ' || COUNT(*) || ' codes' FROM languages GROUP BY type ORDER BY type;"; \
		echo ""; \
		sqlite3 $(SQLITE_DB) "SELECT '  Total: ' || COUNT(*) || ' codes' FROM languages;"; \
	fi
	@echo ""

.PHONY: clean
clean:
	@rm -f $(SQLITE_DB)
	@echo "✓ Database removed"

.PHONY: clean-all
clean-all:
	@rm -rf $(DATA_DIR) $(VENV_DIR)
	@echo "✓ All files removed"

# =============================================================================
# Virtual Environment (skipped in Docker mode)
# =============================================================================
ifndef DOCKER
$(VENV_DIR)/.done:
	@echo "Setting up Python virtual environment..."
	@python3 -m venv $(VENV_DIR)
	@$(PIP) install --upgrade pip -q
	@$(PIP) install datasette datasette-reconcile sqlite-utils -q
	@touch $@
	@echo "✓ Virtual environment ready"
endif

# =============================================================================
# Data Downloads
# =============================================================================
$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(ISO639_2_FILE): | $(DATA_DIR)
	@echo "Downloading ISO 639-2 from Library of Congress..."
	@curl -sL -o $@ "$(ISO639_2_URL)"
	@echo "✓ Downloaded ISO 639-2: $$(wc -l < $@ | tr -d ' ') lines"

$(ISO639_3_FILE): | $(DATA_DIR)
	@echo "Downloading ISO 639-3 from SIL International..."
	@curl -sL -o $@ "$(ISO639_3_URL)"
	@echo "✓ Downloaded ISO 639-3: $$(wc -l < $@ | tr -d ' ') lines"

$(ISO639_5_FILE): | $(DATA_DIR)
	@echo "Downloading ISO 639-5 from Library of Congress..."
	@curl -sL -o $@ "$(ISO639_5_URL)"
	@echo "✓ Downloaded ISO 639-5: $$(wc -l < $@ | tr -d ' ') lines"

# =============================================================================
# Database Build
# =============================================================================
$(SQLITE_DB): $(VENV_DONE) $(ISO639_2_FILE) $(ISO639_3_FILE) $(ISO639_5_FILE) build_db.py
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Building SQLite database"
	@echo "═══════════════════════════════════════════════════════════════"
	@rm -f $(SQLITE_DB)
	@$(PYTHON) build_db.py $(SQLITE_DB) $(ISO639_2_FILE) $(ISO639_3_FILE) $(ISO639_5_FILE)
	@echo "Creating FTS index..."
	@$(SQLITE_UTILS) enable-fts $(SQLITE_DB) languages searchText name --fts5 --create-triggers

$(METADATA_JSON):
	@echo "ERROR: $(METADATA_JSON) not found! Restore from git."
	@exit 1

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "ISO 639 Language Code Reconciliation Service"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Single reconciliation endpoint with type filtering."
	@echo ""
	@echo "Types:"
	@echo "  ISO 639-2  Library of Congress    ~500 codes  (languages)"
	@echo "  ISO 639-3  SIL International    ~8000 codes  (all languages)"
	@echo "  ISO 639-5  Library of Congress    ~115 codes  (families)"
	@echo ""
	@echo "Commands:"
	@echo "  make build     Setup venv + download + database"
	@echo "  make serve     Start server (port $(PORT))"
	@echo "  make status    Show status"
	@echo "  make clean     Remove database"
	@echo "  make clean-all Remove everything"
	@echo ""
	@echo "Endpoint: http://127.0.0.1:$(PORT)/iso639/languages/-/reconcile"
