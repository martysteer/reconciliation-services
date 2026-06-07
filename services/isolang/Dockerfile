# ISO 639 Language Code Reconciliation Service
#
# Build:  docker build -t recon-isolang .
# Run:    docker run -p 8003:8001 recon-isolang

FROM python:3.12-slim

LABEL maintainer="SOAS Library Services"
LABEL description="ISO 639 Language Code Reconciliation Service for OpenRefine"

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    sqlite3 \
    make \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies
RUN pip install --no-cache-dir \
    datasette \
    datasette-reconcile \
    sqlite-utils

# Copy all service files
COPY . .

# Create data directory and build database
RUN mkdir -p data && make build

EXPOSE 8001

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8001/ || exit 1

CMD ["make", "serve", "PUBLIC=1"]
