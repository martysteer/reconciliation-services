# FAST Reconciliation Service
#
# Multi-stage build:
# - Stage 1 (builder): Java/Saxon runs the full data pipeline at IMAGE BUILD time
#                      (MARC XML -> SKOS -> CSV -> SQLite)
# - Stage 2 (runtime): minimal Python/Datasette serving the pre-built database
#
# Build requirements:
# - 12-16GB RAM available to Docker (XSLT transformation; see README)
# - OCLC download may be blocked by Cloudflare. If so, download
#   FASTAll.marcxml.zip manually and place it in this directory
#   (services/fast/) before building -- it will be picked up automatically.
#
# Build:  docker build -t recon-fast .
# Run:    docker run -p 8001:8001 recon-fast

# =============================================================================
# Stage 1: Builder -- Java/Saxon XSLT pipeline, produces /app/data/fast.db
# =============================================================================
FROM eclipse-temurin:17-jdk-jammy AS builder

# Build dependencies (sqlite3 CLI is used by the Makefile's database target)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    make \
    python3 \
    python3-pip \
    sqlite3 \
    && rm -rf /var/lib/apt/lists/*

# Install Saxon HE
RUN mkdir -p /opt/saxon && \
    curl -sL -o /tmp/saxon.zip "https://github.com/Saxonica/Saxon-HE/releases/download/SaxonHE12-5/SaxonHE12-5J.zip" && \
    unzip -j /tmp/saxon.zip "*.jar" -d /opt/saxon && \
    rm /tmp/saxon.zip

# Create Saxon wrapper script (only include required jars)
RUN printf '#!/bin/bash\njava -Xmx8g -cp "/opt/saxon/saxon-he-12.5.jar:/opt/saxon/xmlresolver-5.2.2.jar:/opt/saxon/xmlresolver-5.2.2-data.jar" net.sf.saxon.Transform "$@"\n' > /usr/local/bin/saxon && \
    chmod +x /usr/local/bin/saxon

# Python tool for database building
RUN pip3 install --no-cache-dir sqlite-utils==3.39

WORKDIR /app

# Copy build files. The FASTAll.marcxml.zi[p] glob makes the zip OPTIONAL:
# if you pre-downloaded it (Cloudflare workaround) it is used, otherwise
# the Makefile downloads it.
COPY Makefile fast.metadata.json FASTAll.marcxml.zi[p] ./
COPY xslt/ ./xslt/

# Environment for Docker build mode
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV SAXON=saxon

# Seed pre-downloaded zip into the data dir if present (validating it first --
# a Cloudflare error page saved as .zip would fail cryptically later), then run
# the full pipeline: download (if needed) -> extract -> SKOS -> CSV -> SQLite
RUN mkdir -p /app/data && \
    if [ -f FASTAll.marcxml.zip ]; then \
        unzip -t FASTAll.marcxml.zip >/dev/null && mv FASTAll.marcxml.zip /app/data/; \
    fi && \
    make build

# =============================================================================
# Stage 2: Runtime -- Python/Datasette only (no Java, no Saxon, no make)
# =============================================================================
FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="FAST Reconciliation Service for OpenRefine"

# curl needed for the healthcheck only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    datasette==0.65.2 \
    datasette-reconcile==0.6.3

# Non-root user
RUN useradd --create-home --uid 1000 app

WORKDIR /app

COPY fast.metadata.json ./

# Data dir must be writable by app (SQLite -wal/-shm files)
RUN mkdir -p /app/data && chown app:app /app/data
COPY --from=builder --chown=app:app /app/data/fast.db /app/data/fast.db

USER app

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

# Serve the pre-built database directly (mirrors `make serve PUBLIC=1`)
CMD ["datasette", "/app/data/fast.db", \
     "--metadata", "fast.metadata.json", \
     "--port", "8001", \
     "--host", "0.0.0.0", \
     "--setting", "sql_time_limit_ms", "5000", \
     "--setting", "max_returned_rows", "1000"]
