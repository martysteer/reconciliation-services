#!/usr/bin/env python3
"""Build CLC (Chinese Library Classification) database from JSON sources.

Sources:
  - clc.json: hierarchical classification data from acdzh/Chinese-Library-Classification
    (45,785 entries, 5th edition)
  - clc-en.json: English labels from Wikimedia Commons CategoryTitleTable.json
    (4,851 bilingual mappings)
"""

import json
import sqlite3
import sys


def get_division(class_id):
    """Map top-level letter to broad division."""
    letter = class_id[0].upper()
    if letter == 'A':
        return 'Marxism'
    if letter == 'B':
        return 'Philosophy'
    if letter in 'CDEFGHIJK':
        return 'Social Sciences'
    if letter in 'NOPQRSTUVX':
        return 'Natural Sciences'
    if letter == 'Z':
        return 'Comprehensive'
    return 'Other'


def flatten(entries, broader=None, depth=0):
    """Recursively flatten hierarchical entries."""
    for entry in entries:
        yield (entry['id'], entry['desc'], broader, depth)
        if 'children' in entry:
            yield from flatten(entry['children'], entry['id'], depth + 1)


def main(db_path, clc_file, clc_en_file):
    # Load hierarchical classification data
    with open(clc_file, 'r', encoding='utf-8') as f:
        clc_data = json.load(f)

    # Load English labels (Wikimedia Commons)
    with open(clc_en_file, 'r', encoding='utf-8') as f:
        en_data = json.load(f)

    conn = sqlite3.connect(db_path)
    c = conn.cursor()
    c.execute('''CREATE TABLE IF NOT EXISTS classes (
        id TEXT PRIMARY KEY,
        name TEXT,
        nameEn TEXT,
        edition TEXT,
        division TEXT,
        mainClass TEXT,
        broader TEXT,
        depth INTEGER,
        searchText TEXT
    )''')

    count = 0
    for class_id, name, broader, depth in flatten(clc_data):
        # Look up English label; strip code prefix if present
        en_value = en_data.get(class_id)
        name_en = None
        if en_value:
            if en_value.startswith(class_id):
                name_en = en_value[len(class_id):].strip()
            else:
                name_en = en_value

        division = get_division(class_id)
        main_class = class_id[0].upper()
        search_text = f'{class_id} {name} {name_en or ""}'

        c.execute('''INSERT INTO classes (id, name, nameEn, edition, division, mainClass, broader, depth, searchText)
                     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)''',
                  (class_id, name, name_en, '5', division, main_class, broader, depth, search_text))
        count += 1

    conn.commit()
    conn.close()

    if count == 0:
        print('ERROR: no classes parsed -- source files empty or format changed',
              file=sys.stderr)
        sys.exit(1)
    print(f'\u2713 Database ready: {count} classes')


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('Usage: build_db.py <db_path> <clc.json> <clc-en.json>')
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3])
