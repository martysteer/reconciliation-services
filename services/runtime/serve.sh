#!/bin/sh
# Serve every SQLite database found in /data.
#
# Immutable mode (-i): works on a read-only bind mount (no -wal/-shm files)
# and enables Datasette performance optimisations. Databases are replaced
# wholesale by rebuilding them on the host (`make data`), then restarting.
set -eu

set -- /data/*.db
if [ ! -e "$1" ]; then
    echo "ERROR: no .db files found in /data" >&2
    echo "Run 'make data' on the host to build dataset databases first." >&2
    exit 1
fi

args=""
for db in "$@"; do
    args="$args -i $db"
done

# $args is intentionally word-split: paths are /data/<name>.db (no spaces)
exec datasette serve $args \
    --metadata /app/metadata.json \
    --host 0.0.0.0 \
    --port 8001 \
    --setting sql_time_limit_ms 5000 \
    --setting max_returned_rows 1000
