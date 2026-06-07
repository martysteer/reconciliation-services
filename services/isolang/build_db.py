#!/usr/bin/env python3
"""Build ISO 639 combined database from source files."""

import sqlite3
import csv
import sys

def main(db_path, iso639_2_file, iso639_3_file, iso639_5_file):
    conn = sqlite3.connect(db_path)
    c = conn.cursor()

    # Create combined table
    c.execute('''CREATE TABLE IF NOT EXISTS languages (
        id TEXT PRIMARY KEY,
        name TEXT,
        type TEXT,
        alpha2 TEXT,
        alpha3 TEXT,
        scope TEXT,
        language_type TEXT,
        name_french TEXT,
        searchText TEXT
    )''')

    # === ISO 639-2 ===
    print("Processing ISO 639-2...")
    count = 0
    with open(iso639_2_file, 'r', encoding='utf-8') as f:
        for line in f:
            parts = line.strip().split('|')
            if len(parts) >= 4 and parts[0]:
                alpha3_b = parts[0]
                alpha3_t = parts[1] if len(parts) > 1 else ''
                alpha2 = parts[2] if len(parts) > 2 else ''
                english = parts[3] if len(parts) > 3 else ''
                french = parts[4] if len(parts) > 4 else ''
                code = alpha3_t if alpha3_t else alpha3_b
                search = f'{english} {french} {alpha3_b} {alpha3_t} {alpha2}'
                try:
                    c.execute('''INSERT INTO languages 
                        (id, name, type, alpha2, alpha3, name_french, searchText) 
                        VALUES (?, ?, ?, ?, ?, ?, ?)''',
                        (code, english, 'ISO 639-2', alpha2, code, french, search))
                    count += 1
                except sqlite3.IntegrityError:
                    pass
    print(f"  ISO 639-2: {count} codes")

    # === ISO 639-3 ===
    print("Processing ISO 639-3...")
    count = 0
    with open(iso639_3_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            code = row.get('Id', '')
            if not code:
                continue
            name = row.get('Ref_Name', '')
            alpha2 = row.get('Part1', '')
            scope = row.get('Scope', '')
            lang_type = row.get('Language_Type', '')
            part2b = row.get('Part2b', '')
            part2t = row.get('Part2t', '')
            search = f"{name} {code} {alpha2} {part2b} {part2t}"
            try:
                c.execute('''INSERT INTO languages 
                    (id, name, type, alpha2, alpha3, scope, language_type, searchText) 
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
                    (code, name, 'ISO 639-3', alpha2, code, scope, lang_type, search))
                count += 1
            except sqlite3.IntegrityError:
                pass
    print(f"  ISO 639-3: {count} codes")

    # === ISO 639-5 ===
    print("Processing ISO 639-5...")
    count = 0
    with open(iso639_5_file, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            code = row.get('code', '')
            if not code:
                continue
            name = row.get('Label (English)', '')
            french = row.get('Label (French)', '')
            search = f'{name} {french} {code}'
            try:
                c.execute('''INSERT INTO languages 
                    (id, name, type, alpha3, name_french, searchText) 
                    VALUES (?, ?, ?, ?, ?, ?)''',
                    (code, name, 'ISO 639-5', code, french, search))
                count += 1
            except sqlite3.IntegrityError:
                pass
    print(f"  ISO 639-5: {count} codes")

    # Create indexes
    print("Creating indexes...")
    c.execute('CREATE INDEX IF NOT EXISTS idx_languages_type ON languages(type)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_languages_alpha2 ON languages(alpha2)')
    c.execute('CREATE INDEX IF NOT EXISTS idx_languages_alpha3 ON languages(alpha3)')

    conn.commit()
    
    # Report total
    c.execute('SELECT COUNT(*) FROM languages')
    total = c.fetchone()[0]
    print(f"\n✓ Database ready: {total} total codes")
    
    conn.close()

if __name__ == '__main__':
    if len(sys.argv) != 5:
        print("Usage: build_db.py <db_path> <iso639-2.txt> <iso639-3.tab> <iso639-5.tsv>")
        sys.exit(1)
    main(sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4])
