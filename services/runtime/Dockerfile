# Reconciliation runtime -- one Datasette serving every dataset in /data
#
# Build (context MUST be the repo root):
#   docker build -f services/runtime/Dockerfile -t recon-runtime .
# Run:
#   docker run -d -p 8000:8001 -v "$PWD/data:/data:ro" recon-runtime
#
# Data files are built separately (`make data`) and bind-mounted, so this
# image is small, architecture-cheap, and never needs rebuilding for a
# data refresh -- only when a dataset's metadata or the toolchain changes.

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="Reconciliation Services runtime (Datasette, multi-database)"

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

COPY services/runtime/serve.sh services/runtime/merge_metadata.py ./

# Every dataset contributes its metadata; the glob flattens
# services/<name>/<name>.metadata.json into ./metadata/
COPY services/*/*.metadata.json ./metadata/

RUN python merge_metadata.py metadata/*.metadata.json > metadata.json && \
    chmod +x serve.sh

USER app

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

CMD ["./serve.sh"]
