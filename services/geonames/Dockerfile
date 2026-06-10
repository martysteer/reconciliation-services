# GeoNames Reconciliation Service
#
# Data is downloaded and the SQLite database built at IMAGE BUILD time,
# so the resulting image is self-contained (~3.5GB) and starts instantly.
#
# Build:  docker build -t recon-geonames .   (~400MB download, ~10 min build)
# Run:    docker run -p 8001:8001 recon-geonames

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="GeoNames Reconciliation Service for OpenRefine"

# System dependencies (make/unzip/sqlite3 are needed for the build step)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies (separate layer for caching)
RUN pip install --no-cache-dir \
    datasette==0.65.2 \
    datasette-reconcile==0.6.3 \
    sqlite-utils==3.39 \
    httpx==0.28.1

# Non-root user
RUN useradd --create-home --uid 1000 app

WORKDIR /app

COPY Makefile geonames.metadata.json ./

# Data dir owned by app BEFORE the build so no expensive chown layer is needed
RUN mkdir -p /app/data && chown app:app /app/data

# Environment: Docker mode + data paths
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV GEONAMES_ZIP=/app/data/allCountries.zip
ENV GEONAMES_TXT=/app/data/allCountries.txt
ENV FEATURE_CODES_TXT=/app/data/featureCodes_en.txt
ENV SQLITE_DB=/app/data/geonames.db

USER app

# Build the database at image build time; remove the ~2GB of intermediate
# download/extract files in the SAME layer so they never bloat the image.
RUN make build && \
    rm -f /app/data/allCountries.zip /app/data/allCountries.txt /app/data/featureCodes_en.txt

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

# Serve the pre-built database directly (mirrors `make serve PUBLIC=1`)
CMD ["datasette", "/app/data/geonames.db", \
     "--metadata", "geonames.metadata.json", \
     "--port", "8001", \
     "--host", "0.0.0.0", \
     "--setting", "sql_time_limit_ms", "5000", \
     "--setting", "max_returned_rows", "1000"]
