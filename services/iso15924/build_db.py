#!/usr/bin/env python3
"""Build ISO 15924 script codes database from the Unicode registry file.

Source format (semicolon-delimited, '#' comments):
  Code;N°;English Name;Nom français;PVA;Unicode Version;Date
"""

import sqlite3
import sys


def main(db_path, source_file):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    c.execute('''CREATE TABLE IF NOT EXISTS scripts (
        id TEXT PRIMARY KEY,
        name TEXT,
        code_num TEXT,
        name_french TEXT,
        pva TEXT,
        unicode_version TEXT,
        date TEXT,
        searchText TEXT
    )''')

    count = 0
    with open(source_file, 'r', encoding='utf-8-sig') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split(';')
            if len(parts) < 7:
                continue
            code, num, name, french, pva, unicode_version, date = parts[:7]
            search = ' '.join(p for p in (name, french, pva, code) if p)
            c.execute('''INSERT INTO scripts
                (id, name, code_num, name_french, pva, unicode_version, date, searchText)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                (code, name, num, french, pva, unicode_version, date, search))
            count += 1

    conn.commit()
    conn.close()

    if count == 0:
        print('ERROR: no scripts parsed -- source file empty or format changed',
              file=sys.stderr)
        sys.exit(1)
    print(f'✓ Database ready: {count} scripts')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: build_db.py <db_path> <iso15924.txt>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
