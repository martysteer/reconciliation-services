# FAST Reconciliation Service
#
# Multi-stage build:
# - Stage 1: Java/Saxon for XSLT transformations
# - Stage 2: Python for Datasette runtime
#
# Build:  docker build -t fast-reconcile .
# Run:    docker compose up

# =============================================================================
# Stage 1: Build environment with Java/Saxon for XSLT processing
# =============================================================================
FROM eclipse-temurin:17-jdk-jammy AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    make \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install Saxon HE
RUN mkdir -p /opt/saxon && \
    curl -sL -o /tmp/saxon.zip "https://github.com/Saxonica/Saxon-HE/releases/download/SaxonHE12-5/SaxonHE12-5J.zip" && \
    unzip -j /tmp/saxon.zip "*.jar" -d /opt/saxon && \
    rm /tmp/saxon.zip

# Create Saxon wrapper script (only include required jars)
RUN echo '#!/bin/bash\njava -Xmx8g -cp "/opt/saxon/saxon-he-12.5.jar:/opt/saxon/xmlresolver-5.2.2.jar:/opt/saxon/xmlresolver-5.2.2-data.jar" net.sf.saxon.Transform "$@"' > /usr/local/bin/saxon && \
    chmod +x /usr/local/bin/saxon

# Install Python tools for database building
RUN pip3 install --no-cache-dir sqlite-utils

WORKDIR /app

# Copy build files
COPY Makefile fast.metadata.json ./
COPY xslt/ ./xslt/

# Create data directory
RUN mkdir -p /app/data

# Set environment for Docker build mode
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV SAXON=saxon

# =============================================================================
# Stage 2: Runtime environment with Python/Datasette
# =============================================================================
FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="FAST Reconciliation Service for OpenRefine"

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    sqlite3 \
    make \
    default-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Copy Saxon from builder
COPY --from=builder /opt/saxon /opt/saxon
COPY --from=builder /usr/local/bin/saxon /usr/local/bin/saxon

# Install Python dependencies
RUN pip install --no-cache-dir \
    datasette \
    datasette-reconcile \
    sqlite-utils \
    httpx

WORKDIR /app

# Copy application files
COPY Makefile fast.metadata.json ./
COPY xslt/ ./xslt/

# Create data directory for volume mount
RUN mkdir -p /app/data

# Environment configuration
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV SAXON=saxon

# Expose the datasette port
EXPOSE 8001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

# Default command
CMD ["make", "serve", "PUBLIC=1"]
