# Makefile for FAST Reconciliation Service
#
# Creates a datasette-based reconciliation endpoint for OCLC FAST vocabulary
# compatible with OpenRefine's reconciliation API (W3C Reconciliation Service API v0.2)
#
# Pipeline: MARC XML → SKOS → CSV → SQLite → Datasette
#
# Usage (native):
#   make build    - Complete setup: venv + download + transform + database
#   make serve    - Start datasette reconciliation server (use PUBLIC=1 for network access)
#   make test     - Test FTS and reconciliation endpoint
#   make status   - Show file status and database statistics
#   make update   - Re-download source data and rebuild
#   make clean    - Remove database only (quick reset)
#   make clean-all - Remove everything including downloads and venv
#
# Usage (Docker):
#   docker compose up              - Build and serve (first run downloads data)
#   docker compose run --rm fast make status

# =============================================================================
# Configuration (override with environment variables for Docker)
# =============================================================================
SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DEFAULT_GOAL := help

PYTHON_VERSION ?= 3.12
VENV_DIR ?= .venv

# Data file paths (override for Docker volume mounts)
DATA_DIR ?= data
FAST_URL := https://researchworks.oclc.org/researchdata/fast/FASTAll.marcxml.zip
FAST_ZIP ?= $(DATA_DIR)/FASTAll.marcxml.zip

MARCXML_DIR ?= $(DATA_DIR)/marcxml
SKOS_DIR ?= $(DATA_DIR)/skos
CSV_DIR ?= $(DATA_DIR)/csv

SQLITE_DB ?= $(DATA_DIR)/fast.db
METADATA_JSON ?= fast.metadata.json

PORT ?= 8001

# Docker mode: when DOCKER=1, skip venv and use system tools
DOCKER ?=

# FAST facet tables
FAST_TABLES := FASTChronological FASTCorporate FASTEvent FASTFormGenre \
               FASTGeographic FASTMeeting FASTPersonal FASTTitle FASTTopical

.PRECIOUS: $(FAST_ZIP)

# =============================================================================
# Tool paths (venv or system depending on DOCKER mode)
# =============================================================================
ifdef DOCKER
  PYTHON := python3
  PIP := pip
  DATASETTE := datasette
  SQLITE_UTILS := sqlite-utils
  VENV_DONE :=
  # Use saxon wrapper script (includes xmlresolver jars in classpath)
  SAXON ?= saxon
else
  PYTHON := $(VENV_DIR)/bin/python3
  PIP := $(VENV_DIR)/bin/pip
  DATASETTE := $(VENV_DIR)/bin/datasette
  SQLITE_UTILS := $(VENV_DIR)/bin/sqlite-utils
  VENV_DONE := $(VENV_DIR)/.done
  # macOS Homebrew Saxon path
  SAXON_JAR = $(shell ls /opt/homebrew/opt/saxon/libexec/saxon-he-*.jar 2>/dev/null | grep -v test | grep -v xqj | head -1)
  SAXON := java -Xmx8g -jar $(SAXON_JAR)
endif

# =============================================================================
# Stylesheets
# =============================================================================
XSL_DIR := xslt
MARCXML_TO_SKOS := $(XSL_DIR)/fast2skos.xsl
SKOS_TO_CSV := $(XSL_DIR)/skos2csv-reconcile.xsl

# =============================================================================
# File Discovery
# =============================================================================
MARCXML_FILES = $(wildcard $(MARCXML_DIR)/FAST*.marcxml)
SKOS_FILES = $(patsubst $(MARCXML_DIR)/%.marcxml,$(SKOS_DIR)/%.skosxml,$(MARCXML_FILES))
CSV_FILES = $(patsubst $(SKOS_DIR)/%.skosxml,$(CSV_DIR)/%.csv,$(wildcard $(SKOS_DIR)/*.skosxml))

# Facet type extraction: FASTCorporate -> Corporate
define get_facet_type
$(shell echo "$(1)" | sed -E 's/^FAST//')
endef

# =============================================================================
# Main Targets
# =============================================================================
.PHONY: build
build: $(VENV_DONE) $(SQLITE_DB)
	@echo ""
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "✓ FAST Reconciliation Service is ready!"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Start the server with: make serve"
	@echo ""
	@echo "Primary endpoint: http://127.0.0.1:$(PORT)/fast/FAST/-/reconcile"
	@echo ""

.PHONY: serve
serve: $(VENV_DONE) $(SQLITE_DB) $(METADATA_JSON)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Starting FAST Reconciliation Service"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Primary endpoint (all facets):"
	@echo "  http://127.0.0.1:$(PORT)/fast/FAST/-/reconcile"
	@echo ""
	@echo "Add to OpenRefine:"
	@echo "  1. Column dropdown → Reconcile → Start reconciling..."
	@echo "  2. Click 'Add Standard Service...'"
	@echo "  3. Enter: http://127.0.0.1:$(PORT)/fast/FAST/-/reconcile"
	@echo ""
	@echo "Individual facet endpoints:"
	@for table in $(FAST_TABLES); do \
		echo "  http://127.0.0.1:$(PORT)/fast/$$table/-/reconcile"; \
	done
	@echo ""
	@echo "Press Ctrl+C to stop"
	@echo "═══════════════════════════════════════════════════════════════"
	@HOST=$${PUBLIC:+0.0.0.0}; HOST=$${HOST:-127.0.0.1}; \
	$(DATASETTE) $(SQLITE_DB) \
		--metadata $(METADATA_JSON) \
		--port $(PORT) \
		--host $$HOST \
		--setting sql_time_limit_ms 5000 \
		--setting max_returned_rows 1000

.PHONY: test
test: $(VENV_DONE) $(SQLITE_DB)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Testing FAST Service"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "FTS search for 'Shakespeare':"
	@sqlite3 -header -column $(SQLITE_DB) " \
		SELECT f.id, f.name, f.type \
		FROM FAST f \
		INNER JOIN FAST_fts fts ON f.rowid = fts.rowid \
		WHERE FAST_fts MATCH 'Shakespeare' \
		LIMIT 5;"
	@echo ""
	@echo "Reconciliation endpoint test:"
	@$(PYTHON) -c " \
import json, httpx; \
queries = {'q0': {'query': 'Shakespeare'}, 'q1': {'query': 'London'}}; \
try: \
    r = httpx.post('http://127.0.0.1:$(PORT)/fast/FAST/-/reconcile', \
        data={'queries': json.dumps(queries)}, timeout=10); \
    print(json.dumps(r.json(), indent=2)); \
except httpx.ConnectError: \
    print('Server not running. Start with: make serve'); \
"

.PHONY: status
status:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "FAST Reconciliation Service Status"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Files:"
	@if [ -n "$(VENV_DONE)" ] && [ -f "$(VENV_DONE)" ]; then echo "  ✓ venv"; elif [ -z "$(VENV_DONE)" ]; then echo "  ✓ system (Docker)"; else echo "  ✗ venv"; fi
	@if [ -f "$(FAST_ZIP)" ]; then echo "  ✓ $(FAST_ZIP) ($$(du -h $(FAST_ZIP) | cut -f1))"; else echo "  ✗ $(FAST_ZIP)"; fi
	@if [ -d "$(MARCXML_DIR)" ] && [ -f "$(MARCXML_DIR)/.extracted" ]; then echo "  ✓ $(MARCXML_DIR)/ ($$(ls -1 $(MARCXML_DIR)/FAST*.marcxml 2>/dev/null | wc -l | tr -d ' ') files)"; else echo "  ✗ $(MARCXML_DIR)/"; fi
	@if [ -d "$(SKOS_DIR)" ]; then \
		COUNT=$$(ls -1 $(SKOS_DIR)/*.skosxml 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$COUNT" -gt 0 ]; then echo "  ✓ $(SKOS_DIR)/ ($$COUNT files)"; else echo "  ✗ $(SKOS_DIR)/ (empty)"; fi; \
	else echo "  ✗ $(SKOS_DIR)/"; fi
	@if [ -d "$(CSV_DIR)" ]; then \
		COUNT=$$(ls -1 $(CSV_DIR)/*.csv 2>/dev/null | wc -l | tr -d ' '); \
		if [ "$$COUNT" -gt 0 ]; then echo "  ✓ $(CSV_DIR)/ ($$COUNT files)"; else echo "  ✗ $(CSV_DIR)/ (empty)"; fi; \
	else echo "  ✗ $(CSV_DIR)/"; fi
	@if [ -f "$(SQLITE_DB)" ]; then echo "  ✓ $(SQLITE_DB) ($$(du -h $(SQLITE_DB) | cut -f1))"; else echo "  ✗ $(SQLITE_DB)"; fi
	@if [ -f "$(METADATA_JSON)" ]; then echo "  ✓ $(METADATA_JSON)"; else echo "  ✗ $(METADATA_JSON) (missing!)"; fi
	@echo ""
	@if [ -f "$(SQLITE_DB)" ]; then \
		echo "Database:"; \
		for table in $(FAST_TABLES) FAST; do \
			COUNT=$$(sqlite3 $(SQLITE_DB) "SELECT COUNT(*) FROM $$table;" 2>/dev/null || echo "0"); \
			printf "  %-20s %'10d records\n" "$$table" "$$COUNT"; \
		done; \
	fi
	@echo ""

.PHONY: update
update: clean-data
	@echo "Re-downloading and rebuilding..."
	@$(MAKE) build

.PHONY: clean
clean:
	@echo "Removing database..."
	@rm -f $(SQLITE_DB)
	@echo "✓ Done. Run 'make build' to rebuild."

.PHONY: clean-csv
clean-csv:
	@echo "Removing database and CSV files (keeping SKOS)..."
	@rm -f $(SQLITE_DB)
	@rm -rf $(CSV_DIR)
	@echo "✓ Done. SKOS files preserved in $(SKOS_DIR)/"

.PHONY: clean-data
clean-data:
	@echo "Removing all derived data (keeping source zip and SKOS)..."
	@rm -f $(SQLITE_DB)
	@rm -rf $(CSV_DIR)
	@rm -f $(MARCXML_DIR)/.extracted
	@echo "✓ Data files removed. SKOS files preserved in $(SKOS_DIR)/"

.PHONY: clean-all
clean-all:
	@echo "Removing ALL generated files (including SKOS)..."
	@rm -rf $(DATA_DIR) $(VENV_DIR) .python-version
	@echo "✓ All files removed."

# =============================================================================
# Virtual Environment
# =============================================================================
.PHONY: venv
venv: $(VENV_DONE)

$(VENV_DIR)/.done:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Setting up Python virtual environment"
	@echo "═══════════════════════════════════════════════════════════════"
ifndef DOCKER
	@# Check for Homebrew (macOS)
	@if command -v brew >/dev/null 2>&1; then \
		if ! ls /opt/homebrew/opt/saxon/libexec/saxon-he-*.jar >/dev/null 2>&1; then \
			echo "Installing Saxon via Homebrew..."; \
			brew install saxon; \
		else \
			echo "✓ Saxon already installed"; \
		fi; \
	else \
		echo "Note: Install Saxon manually if not using Homebrew"; \
	fi
	@# Check for Java
	@command -v java >/dev/null 2>&1 || { echo "ERROR: Java not found. Install JDK."; exit 1; }
endif
	@python3 -m venv $(VENV_DIR)
	@$(PIP) install --upgrade pip -q
	@$(PIP) install datasette datasette-reconcile sqlite-utils httpx -q
	@touch $@
	@echo "✓ Virtual environment ready"

# =============================================================================
# Download and Extract
# =============================================================================
.PHONY: download
download: $(FAST_ZIP)

$(DATA_DIR):
	@mkdir -p $(DATA_DIR)

$(FAST_ZIP): | $(DATA_DIR)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Downloading FAST data from OCLC (~198MB)"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "NOTE: OCLC uses Cloudflare protection which may block automated downloads."
	@echo ""
	@echo "Attempting download with browser-like headers..."
	@echo "  URL: $(FAST_URL)"
	@curl -L --progress-bar \
		-A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
		-H "Accept: application/zip,application/octet-stream,*/*" \
		-H "Accept-Language: en-US,en;q=0.9" \
		--compressed \
		-o $@ "$(FAST_URL)" || true
	@# Verify download is a valid zip file
	@if [ ! -f $@ ] || ! unzip -t $@ >/dev/null 2>&1; then \
		echo ""; \
		echo "═══════════════════════════════════════════════════════════════"; \
		echo "DOWNLOAD BLOCKED BY CLOUDFLARE"; \
		echo "═══════════════════════════════════════════════════════════════"; \
		echo ""; \
		echo "The OCLC server blocked the automated download."; \
		echo ""; \
		echo "Please download manually:"; \
		echo "  1. Open this URL in your browser:"; \
		echo "     $(FAST_URL)"; \
		echo ""; \
		echo "  2. Save the file to:"; \
		echo "     $(FAST_ZIP)"; \
		echo ""; \
		echo "  3. Then run 'make build' again."; \
		echo ""; \
		rm -f $@; \
		exit 1; \
	fi
	@echo ""
	@echo "✓ Downloaded: $$(du -h $@ | cut -f1)"

.PHONY: extract
extract: $(MARCXML_DIR)/.extracted

$(MARCXML_DIR)/.extracted: $(FAST_ZIP)
	@echo "Extracting $(FAST_ZIP)..."
	@mkdir -p $(MARCXML_DIR)
	@unzip -o -d $(MARCXML_DIR) $(FAST_ZIP)
	@touch $@
	@echo "  Extracted $$(ls -1 $(MARCXML_DIR)/FAST*.marcxml 2>/dev/null | wc -l | tr -d ' ') MARC XML files"

# =============================================================================
# Directory Creation
# =============================================================================
$(SKOS_DIR):
	@mkdir -p $(SKOS_DIR)

$(CSV_DIR):
	@mkdir -p $(CSV_DIR)

# =============================================================================
# Pipeline: MARC XML → SKOS
# =============================================================================
# Sentinel file tracks when SKOS conversion is complete
$(SKOS_DIR)/.done: $(VENV_DONE) $(MARCXML_DIR)/.extracted $(MARCXML_TO_SKOS) | $(SKOS_DIR)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Converting MARC XML → SKOS"
	@echo "═══════════════════════════════════════════════════════════════"
	@for marcxml in $(MARCXML_DIR)/FAST*.marcxml; do \
		base=$$(basename "$$marcxml" .marcxml); \
		skosxml="$(SKOS_DIR)/$$base.skosxml"; \
		if [ ! -f "$$skosxml" ] || [ "$$marcxml" -nt "$$skosxml" ]; then \
			facet=$$(echo "$$base" | sed 's/^FAST//'); \
			echo "  $$base.marcxml → $$base.skosxml (facet: $$facet)"; \
			$(SAXON) -s:"$$marcxml" -xsl:$(MARCXML_TO_SKOS) -o:"$$skosxml" facetType="$$facet"; \
		fi; \
	done
	@touch $@
	@echo "✓ SKOS conversion complete"

# Manual target for running SKOS conversion
.PHONY: skos
skos: $(SKOS_DIR)/.done

# =============================================================================
# Pipeline: SKOS → CSV
# =============================================================================
# Sentinel file tracks when CSV conversion is complete
$(CSV_DIR)/.done: $(SKOS_DIR)/.done $(SKOS_TO_CSV) | $(CSV_DIR)
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Converting SKOS → CSV"
	@echo "═══════════════════════════════════════════════════════════════"
	@for skosxml in $(SKOS_DIR)/FAST*.skosxml; do \
		base=$$(basename "$$skosxml" .skosxml); \
		csvfile="$(CSV_DIR)/$$base.csv"; \
		if [ ! -f "$$csvfile" ] || [ "$$skosxml" -nt "$$csvfile" ]; then \
			facet=$$(echo "$$base" | sed 's/^FAST//'); \
			echo "  $$base.skosxml → $$base.csv"; \
			$(SAXON) -s:"$$skosxml" -xsl:$(SKOS_TO_CSV) -o:"$$csvfile" facetType="$$facet"; \
		fi; \
	done
	@touch $@
	@echo "✓ CSV conversion complete"

# Manual target for running CSV conversion
.PHONY: csv
csv: $(CSV_DIR)/.done

# =============================================================================
# Pipeline: CSV → SQLite Database
# =============================================================================
$(SQLITE_DB): $(CSV_DIR)/.done
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "Building SQLite database with FTS indexes"
	@echo "═══════════════════════════════════════════════════════════════"
	@rm -f $(SQLITE_DB)
	@# Import each CSV into its own table
	@for table in $(FAST_TABLES); do \
		csv_file="$(CSV_DIR)/$${table}.csv"; \
		if [ -f "$$csv_file" ]; then \
			echo "  Importing $$table..."; \
			$(SQLITE_UTILS) insert $(SQLITE_DB) $$table "$$csv_file" --csv; \
		fi; \
	done
	@# Create combined FAST table from all facets
	@echo "  Creating combined FAST table..."
	@FIRST=1; for table in $(FAST_TABLES); do \
		if [ $$FIRST -eq 1 ]; then \
			sqlite3 $(SQLITE_DB) "CREATE TABLE FAST AS SELECT * FROM $$table;"; \
			FIRST=0; \
		else \
			sqlite3 $(SQLITE_DB) "INSERT INTO FAST SELECT * FROM $$table;"; \
		fi; \
	done
	@# Create FTS5 indexes
	@echo "  Creating FTS5 indexes..."
	@for table in $(FAST_TABLES) FAST; do \
		$(SQLITE_UTILS) enable-fts $(SQLITE_DB) $$table searchText name --fts5 --create-triggers 2>/dev/null || true; \
	done
	@# Create indexes on id and type fields
	@echo "  Creating indexes..."
	@for table in $(FAST_TABLES) FAST; do \
		sqlite3 $(SQLITE_DB) "CREATE INDEX IF NOT EXISTS idx_$${table}_id ON $$table(id);"; \
		sqlite3 $(SQLITE_DB) "CREATE INDEX IF NOT EXISTS idx_$${table}_type ON $$table(type);"; \
	done
	@echo ""
	@echo "✓ Database ready: $$(du -h $(SQLITE_DB) | cut -f1)"
	@sqlite3 $(SQLITE_DB) "SELECT '  FAST (combined): ' || COUNT(*) || ' records' FROM FAST;"

$(METADATA_JSON):
	@echo "ERROR: $(METADATA_JSON) not found!"
	@echo "This file configures the reconciliation service and must be present."
	@echo "Restore from git or create manually."
	@exit 1

# =============================================================================
# Utilities
# =============================================================================
.PHONY: install-saxon
install-saxon:
	@echo "Installing Saxon via Homebrew..."
	@brew install saxon
	@echo "✓ Saxon installed"

# =============================================================================
# Help
# =============================================================================
.PHONY: help
help:
	@echo "═══════════════════════════════════════════════════════════════"
	@echo "FAST Reconciliation Service"
	@echo "═══════════════════════════════════════════════════════════════"
	@echo ""
	@echo "Datasette-based reconciliation endpoint for OCLC FAST vocabulary,"
	@echo "compatible with OpenRefine's W3C Reconciliation API."
	@echo ""
	@echo "Pipeline: MARC XML → SKOS → CSV → SQLite → Datasette"
	@echo ""
	@echo "Native usage:"
	@echo "  make build      Complete setup: venv + download + transform + database"
	@echo "  make serve      Start server (use PUBLIC=1 for network access)"
	@echo "  make test       Test FTS search and reconciliation endpoint"
	@echo "  make status     Show file status and database statistics"
	@echo "  make update     Re-download source data and rebuild"
	@echo "  make clean      Remove database only"
	@echo "  make clean-csv  Remove database + CSV (keeps SKOS)"
	@echo "  make clean-data Remove database + CSV + extracted MARC (keeps SKOS + zip)"
	@echo "  make clean-all  Remove everything including SKOS, downloads, and venv"
	@echo "  make venv       Create Python virtual environment only"
	@echo ""
	@echo "Pipeline stages (for manual control):"
	@echo "  make download   Download FASTAll.marcxml.zip from OCLC"
	@echo "  make extract    Extract zip to $(MARCXML_DIR)/"
	@echo "  make skos       Convert MARC XML → SKOS"
	@echo "  make csv        Convert SKOS → CSV"
	@echo ""
	@echo "Docker usage:"
	@echo "  docker compose up           Build and start service"
	@echo "  docker compose run --rm fast make status"
	@echo ""
	@echo "Quick start:"
	@echo "  make build && make serve"
	@echo ""
	@echo "Primary endpoint: http://127.0.0.1:$(PORT)/fast/FAST/-/reconcile"
	@echo ""
