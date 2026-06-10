# GeoNames dataset builder
#
# Builds geonames.db at IMAGE BUILD time (~400MB download, ~10 min). The
# final stage contains ONLY the database file -- export it to the host:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="geonames"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).

FROM python:3.12-slim AS builder

LABEL maintainer="SOAS Library Services"
LABEL description="GeoNames dataset builder for the reconciliation runtime"

# System dependencies for the data pipeline
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir sqlite-utils==3.39

WORKDIR /app

COPY Makefile ./

# Environment: Docker mode + data paths
ENV DOCKER=1
ENV DATA_DIR=/app/data
ENV GEONAMES_ZIP=/app/data/allCountries.zip
ENV GEONAMES_TXT=/app/data/allCountries.txt
ENV FEATURE_CODES_TXT=/app/data/featureCodes_en.txt
ENV SQLITE_DB=/app/data/geonames.db

# Build the database at image build time; remove the ~2GB of intermediate
# download/extract files in the SAME layer so they never bloat the
# builder image / build cache.
RUN mkdir -p /app/data && \
    make build && \
    rm -f /app/data/allCountries.zip /app/data/allCountries.txt /app/data/featureCodes_en.txt

# =============================================================================
# Export stage: just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/geonames.db /
