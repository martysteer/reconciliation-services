# ISO 639 dataset builder
#
# Builds iso639.db at IMAGE BUILD time. The final stage contains ONLY the
# database file -- export it to the host with BuildKit:
#
#   docker build --target export --output type=local,dest=../../data .
#
# (or `make data SERVICES="isolang"` from the repo root)
# Serving is done by the shared runtime image (services/runtime/).

FROM python:3.12-slim AS builder

LABEL maintainer="SOAS Library Services"
LABEL description="ISO 639 dataset builder for the reconciliation runtime"

# System dependencies for the data pipeline
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir sqlite-utils==3.39

WORKDIR /app

# Selective copy keeps the build context explicit and preserves layer caching
COPY Makefile build_db.py ./

# Docker mode: use system Python, skip venv
ENV DOCKER=1

# Download source data and build the database at image build time
RUN make build

# =============================================================================
# Export stage: just the database, for `docker build --output`
# =============================================================================
FROM scratch AS export
COPY --from=builder /app/data/iso639.db /
