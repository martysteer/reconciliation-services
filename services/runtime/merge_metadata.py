#!/usr/bin/env python3
"""Merge per-dataset Datasette metadata files into one runtime metadata.json.

Usage: merge_metadata.py <file.metadata.json>... > metadata.json

Each services/<name>/<name>.metadata.json contributes its "databases"
section. Top-level license/source attribution in each file is pushed down
into its database entries so it survives the merge.

A directory of reconciliation endpoints is auto-generated from the merged
metadata and written to the top-level "description_html", which Datasette
renders on its homepage. Links are relative, so they resolve against
whatever host serves the instance (e.g. the ngrok dev domain).
"""
import json
import sys
from html import escape
from pathlib import Path

ATTRIBUTION_KEYS = ("license", "license_url", "source", "source_url", "description")

# datasette-reconcile serves each configured table here:
RECONCILE_PATH = "/{db}/{table}/-/reconcile"


def merge(paths):
    merged = {
        "title": "Reconciliation Services",
        "description": "W3C Reconciliation Service API endpoints for OpenRefine",
        "databases": {},
    }
    # Per-dataset titles aren't pushed into the database entries, so capture
    # them here while we still have each source document.
    titles = {}
    for path in sorted(paths):
        doc = json.loads(Path(path).read_text())
        for db_name, db in doc.get("databases", {}).items():
            if db_name in merged["databases"]:
                raise SystemExit(f"Duplicate database name '{db_name}' in {path}")
            for key in ATTRIBUTION_KEYS:
                if key in doc and key not in db:
                    db[key] = doc[key]
            if "title" in doc:
                titles[db_name] = doc["title"]
            merged["databases"][db_name] = db
    merged["description_html"] = build_index_html(merged["databases"], titles)
    return merged


def build_index_html(databases, titles):
    """Render a homepage directory of every reconciliation endpoint."""
    out = [
        "<p>OpenRefine-compatible <strong>reconciliation endpoints</strong>. "
        "In OpenRefine, add a reconciliation service using the endpoint URL "
        "for the dataset you want (each URL returns its service manifest as JSON).</p>",
    ]
    for db_name, db in databases.items():
        recon = [
            (table, tv)
            for table, tv in db.get("tables", {}).items()
            if tv.get("plugins", {}).get("datasette-reconcile")
        ]
        if not recon:
            continue
        heading = titles.get(db_name, db_name)
        out.append(f"<h3>{escape(heading)}</h3>")
        out.append("<ul>")
        for table, tv in recon:
            rec = tv["plugins"]["datasette-reconcile"]
            name = rec.get("service_name") or tv.get("title") or table
            desc = tv.get("description", "")
            url = RECONCILE_PATH.format(db=db_name, table=table)
            line = (
                f'<li><a href="{escape(url)}"><strong>{escape(name)}</strong></a> '
                f'&mdash; <code>{escape(url)}</code>'
            )
            if desc:
                line += f"<br><small>{escape(desc)}</small>"
            line += "</li>"
            out.append(line)
        out.append("</ul>")
    return "\n".join(out)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    json.dump(merge(sys.argv[1:]), sys.stdout, indent=2)
    print()
