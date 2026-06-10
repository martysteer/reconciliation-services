# FAST dataset builder
#
# Stage 1 (builder): Java/Saxon runs the full data pipeline at IMAGE BUILD
#                    time (MARC XML -> SKOS -> CSV -> SQLite). Needs 12-16GB
#                    RAM available to Docker (see README).
# Stage 2 (export):  contains ONLY fast.db -- export it to the host:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="fast"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).
#
# OCLC download may be blocked by Cloudflare. If so, download
# FASTAll.marcxml.zip manually and place it in this directory
# (services/fast/) before building -- it will be picked up automatically.

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
COPY Makefile FASTAll.marcxml.zi[p] ./
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
# Stage 2: Export -- just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/fast.db /
