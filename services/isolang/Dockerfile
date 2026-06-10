# ISO 639 Language Code Reconciliation Service
#
# Data is downloaded and the SQLite database built at IMAGE BUILD time,
# so the resulting image is self-contained and starts instantly.
#
# Build:  docker build -t recon-isolang .
# Run:    docker run -p 8003:8001 recon-isolang

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="ISO 639 Language Code Reconciliation Service for OpenRefine"

# System dependencies (make/sqlite3 are needed for the build step)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies
RUN pip install --no-cache-dir \
    datasette==0.65.2 \
    datasette-reconcile==0.6.3 \
    sqlite-utils==3.39

# Non-root user
RUN useradd --create-home --uid 1000 app

WORKDIR /app

# Selective copy keeps the build context explicit and preserves layer caching
COPY Makefile iso639.metadata.json build_db.py ./

RUN mkdir -p /app/data && chown app:app /app/data

# Docker mode: use system Python, skip venv
ENV DOCKER=1

USER app

# Download source data and build the database at image build time
RUN make build

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

# Serve the pre-built database directly (mirrors `make serve PUBLIC=1`)
CMD ["datasette", "/app/data/iso639.db", \
     "--metadata", "iso639.metadata.json", \
     "--port", "8001", \
     "--host", "0.0.0.0"]
