#!/usr/bin/env python3
"""Build Problem LCSH database from the Cataloging Lab HTML page.

Source: https://cataloginglab.org/problem-lcsh/ -- an HTML page containing a
table (class "igsv-table") with three columns: Current LCSH, Preferred term,
and Comments. Rows are parsed from the <tbody> and inserted as-is, including
duplicate heading names (which represent different viewpoints).
"""

import sqlite3
import sys

from bs4 import BeautifulSoup


def main(db_path, source_file):
    with open(source_file, 'r', encoding='utf-8') as f:
        soup = BeautifulSoup(f, 'html.parser')

    table = soup.find('table', class_='igsv-table')
    if not table:
        print('ERROR: no table with class "igsv-table" found -- page format may have changed',
              file=sys.stderr)
        sys.exit(1)

    tbody = table.find('tbody')
    if not tbody:
        print('ERROR: no <tbody> found in table', file=sys.stderr)
        sys.exit(1)

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS headings (
        id INTEGER PRIMARY KEY,
        name TEXT,
        preferred TEXT,
        comments TEXT,
        searchText TEXT
    )''')

    count = 0
    for row in tbody.find_all('tr'):
        cells = row.find_all('td')
        if len(cells) < 3:
            continue
        name = cells[0].get_text(strip=True)
        preferred = cells[1].get_text(strip=True)
        comments = cells[2].get_text(strip=True)
        if not name:
            continue
        search_text = f'{name} {preferred}'
        c.execute('''INSERT INTO headings (name, preferred, comments, searchText)
                     VALUES (?, ?, ?, ?)''',
                  (name, preferred, comments, search_text))
        count += 1

    conn.commit()
    conn.close()

    if count == 0:
        print('ERROR: no headings parsed -- source file empty or format changed',
              file=sys.stderr)
        sys.exit(1)
    print(f'✓ Database ready: {count} headings')


if __name__ == '__main__':
    if len(sys.argv) != 3:
        print('Usage: build_db.py <db_path> <problem-lcsh.html>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2])
