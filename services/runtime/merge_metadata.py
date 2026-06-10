#!/usr/bin/env python3
"""Merge per-dataset Datasette metadata files into one runtime metadata.json.

Usage: merge_metadata.py <file.metadata.json>... > metadata.json

Each services/<name>/<name>.metadata.json contributes its "databases"
section. Top-level license/source attribution in each file is pushed down
into its database entries so it survives the merge.
"""
import json
import sys
from pathlib import Path

ATTRIBUTION_KEYS = ("license", "license_url", "source", "source_url", "description")


def merge(paths):
    merged = {
        "title": "Reconciliation Services",
        "description": "W3C Reconciliation Service API endpoints for OpenRefine",
        "databases": {},
    }
    for path in sorted(paths):
        doc = json.loads(Path(path).read_text())
        for db_name, db in doc.get("databases", {}).items():
            if db_name in merged["databases"]:
                raise SystemExit(f"Duplicate database name '{db_name}' in {path}")
            for key in ATTRIBUTION_KEYS:
                if key in doc and key not in db:
                    db[key] = doc[key]
            merged["databases"][db_name] = db
    return merged


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    json.dump(merge(sys.argv[1:]), sys.stdout, indent=2)
    print()
