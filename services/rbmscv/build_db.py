#!/usr/bin/env python3
"""Build RBMS Controlled Vocabulary database from the LOC scheme JSON-LD.

Source: https://id.loc.gov/vocabulary/rbmscv.json -- a flat JSON-LD array
containing the MADS scheme plus ~1476 term entries. Term entries have an
@id under the rbmscv/ prefix and a madsrdf authoritativeLabel (values are
sometimes duplicated in the source; first wins).
"""

import json
import sqlite3
import sys

TERM_PREFIX = 'http://id.loc.gov/vocabulary/rbmscv/'
LABEL_KEY = 'http://www.loc.gov/mads/rdf/v1#authoritativeLabel'


def main(db_path, source_file):
    with open(source_file, 'r', encoding='utf-8') as f:
        entries = json.load(f)

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS terms (
        id TEXT PRIMARY KEY,
        uri TEXT,
        name TEXT,
        searchText TEXT
    )''')

    count = 0
    for entry in entries:
        uri = entry.get('@id', '')
        if not uri.startswith(TERM_PREFIX):
            continue
        labels = [v.get('@value', '') for v in entry.get(LABEL_KEY, [])]
        labels = [label for label in labels if label]
        if not labels:
            continue
        name = labels[0]
        term_id = uri[len(TERM_PREFIX):]
        c.execute('''INSERT OR IGNORE INTO terms (id, uri, name, searchText)
                     VALUES (?, ?, ?, ?)''',
                  (term_id, uri, name, name))
        count += 1

    conn.commit()
    conn.close()

    if count == 0:
        print('ERROR: no terms parsed -- source file empty or format changed',
              file=sys.stderr)
        sys.exit(1)
    print(f'✓ Database ready: {count} terms')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: build_db.py <db_path> <rbmscv.json>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
