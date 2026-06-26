# Chinese Library Classification (CLC) Reconciliation Service — Build Plan

## Overview

Add a CLC reconciliation service with **edition awareness**. Service name: `clc`. Database: `clc.db`. Table: `classes`. Endpoint: `/clc/classes/-/reconcile`.

CLC (中国图书馆分类法) is China's national library classification system, used by 94%+ of Chinese libraries and by publishers to classify all books published in China. 5 editions (1975-2010), 22 top-level classes (A-Z, skipping L/M/W/Y), ~43,600 categories in the 5th edition.

The service should include the current (5th) edition as primary data, with edition metadata so users can filter or understand which version a class belongs to.

---

## 1. Data Sources — Evaluated

### Primary: acdzh/Chinese-Library-Classification (GitHub)

- **URL:** https://github.com/acdzh/Chinese-Library-Classification
- **Key file:** `clc.json` — **45,785 entries**, complete 5th edition
- **Format:** Hierarchical JSON with `id`, `desc`, `children`
- **Raw URL:** `https://raw.githubusercontent.com/acdzh/Chinese-Library-Classification/master/clc.json`
- **Live preview:** https://acdzh.github.io/Chinese-Library-Classification/
- **License:** Non-commercial use only
- **Last updated:** June 14, 2023
- **Depth:** 5-6 levels deep — far more complete than HuggingFace
- **Concern:** "Non-commercial" license. Reconciliation service is non-commercial (library/academic tool), so this should be acceptable. Confirm before proceeding.

### Secondary: agentlans/library-classification-systems (HuggingFace)

- **URL:** https://huggingface.co/datasets/agentlans/library-classification-systems
- **CLC file:** `CLC.jsonl.gz` (132 KB compressed)
- **Records:** 8,826 entries (first 3 hierarchy levels only)
- **Format:** JSONL — fields: `call_number`, `description`, `broader`, `narrower`
- **License:** CC BY 4.0
- **Collected:** 2024-09-18 from CLC Index
- **Limitation:** Only 3 levels deep (~20% of full classification)

### English Labels: Wikimedia Commons CategoryTitleTable

- **URL:** `https://commons.wikimedia.org/w/index.php?title=Module:Library_classification_navigation/CLC/CategoryTitleTable.json&action=raw`
- **Records:** 4,852 entries mapping CLC codes to English labels
- **Format:** Flat JSON `{"D621.5": "D621.5 Civil Rights", ...}`
- **License:** CC BY-SA
- **Use:** Merge English names into DB as `nameEn` column for bilingual search

### Scrapable Web Sources

- **https://www.clcindex.com/category/{CODE}/** — comprehensive CLC lookup, Wikidata P1189 formatter URL
- **https://www.ztflh.com/** — another CLC reference site
- **https://ztflh.xhma.com/** — third-party CLC lookup (source for `sheoguo` pip package)

### Official (Unreachable Outside China)

- **http://clc.nlc.cn/** — NLC official CLC site (timeout from outside China)
- **http://clc5.nlc.cn/** — 5th edition web version (requires login, timeout)

### Other References

- **LOC Linked Data:** `http://id.loc.gov/vocabulary/classSchemes/clc` — metadata stub only (MARC code: "clc"), no class data
- **BARTOC:** https://bartoc.org/en/node/893 — metadata only (Wikidata Q5100524)
- **Wikidata:** Q5100524 (system), P1189 (CLC code property, only 23 items populated)
- **PyPI:** `chinese-library-classification` (pip, MIT, wraps scraped data)
- **PDF:** 4th edition available on GitHub (ProletRevDicta repo); ZJU summary at https://jzus.zju.edu.cn/download/clc.pdf
- **GitCode:** 42,354 items in XLS/CSV/SQL (license unclear)

### Source Decision

| Criterion | acdzh (GitHub) | agentlans (HuggingFace) |
|-----------|---------------|------------------------|
| Entries | **45,785** | 8,826 |
| Depth | 5-6 levels | 3 levels |
| License | Non-commercial | **CC BY 4.0** |
| Format | Hierarchical JSON | Flat JSONL |
| English labels | No | No |

**Recommendation:** Use **HuggingFace** as primary (clean license), supplement with **Wikimedia Commons** English labels. If non-commercial license is acceptable, switch to **acdzh** for full depth. Flag for user decision.

---

## 2. Edition History

### CLC Editions

| Ed. | Year | Publisher | ISBN | Key Changes |
|-----|------|-----------|------|-------------|
| 1st | 1975 | 科学技术文献出版社 | (pre-ISBN) | Original 22 classes. Compiled during Cultural Revolution. Political stance influenced classification. |
| 2nd | 1980 | 书目文献出版社 | 统一书号 7201-10 | Corrected political errors of 1st ed. Removed ideological slogans. |
| 3rd | 1990 | 书目文献出版社 | 7501309078 | General revision. Also published in Uyghur and Japanese. |
| 4th | 1999 | 北京图书馆出版社 | 978-7-5013-1603-8 | **Major.** Merged with CBDC. Renamed from 中国图书馆图书分类法 to 中国图书馆分类法. Added Deng Xiaoping Theory to class A. Added "+" notation for article-only categories. Electronic CD-ROM in 2001. |
| 5th | 2010 | 国家图书馆出版社 | 978-7-5013-4393-5 | **Largest.** +1,631 new categories, -2,500 deleted, ~5,200 modified. Web version 2011. Used by 94%+ of Chinese libraries. |

### Machine-Readable Data by Edition

- **1st-3rd editions:** No machine-readable data exists. Print only.
- **4th edition (1999):** PDF on GitHub (ProletRevDicta repo). CD-ROM existed but not freely available.
- **5th edition (2010):** Multiple sources (see above). acdzh JSON has 45,785 entries.
- **4th↔5th comparison table:** Published by NLC but not found in open digital form.

### Top-Level Classes Across Editions

The 22-class structure (A-K, N-X, Z) has been **constant since 1975**. Letters L, M, W, Y reserved for future use. Only naming change: Class A added "邓小平理论" in 4th ed.

### Version Strategy for Reconciliation Service

Since no machine-readable data exists for editions 1-3, and 4th edition is only in PDF:

**Practical approach:** Build with 5th edition data. Add `edition` column defaulting to `"5"`. Include an `edition_note` field for classes known to have changed between editions. This provides version context without requiring unavailable historical data.

If 4th-edition PDF is later parsed, those entries can be added with `edition: "4"` and the service becomes multi-edition.

---

## 3. Related Chinese Classification Systems

### 3a. CBDC — Chinese Book and Document Classification (中国图书资料分类法)

- **Not a separate service** — merged into CLC 4th edition (1999)
- Same 22-class structure as CLC but with finer subdivision for articles/papers
- Categories unique to CBDC marked with "+" in CLC 4th/5th editions
- **Action:** Capture "+" notation in `build_db.py` if present in source data. Add boolean `articleOnly` column.

### 3b. CASLC — Chinese Academy of Sciences Library Classification (科图法)

- **Structure:** 5 divisions, 25 classes, pure Arabic numerals (00-90)
- **Editions:** 1958, 1974 (internal), 1979, 1994 (3rd, ISBN 7030037820)
- **Status:** Largely superseded by CLC. Still used in CAS/CASS libraries.
- **Machine-readable data:** None found publicly. Would need to scrape or manually enter.
- **Action:** Stub service. Top-level 25 classes can be hardcoded from known sources. Full data TBD.

### 3c. RUCLC — Renmin University Library Classification (人大法)

- **Structure:** 4 divisions, 17 classes, Arabic numerals
- **Created:** 1953 (China's first post-1949 classification)
- **Status:** Abandoned. Renmin University itself converted to CLC (completed 2011 for post-1995 books).
- **Machine-readable data:** None found.
- **Action:** Stub service. Historical interest only. Top-level classes can be hardcoded if 17-class list is confirmed.

### 3d. NCSCL — New Classification Scheme for Chinese Libraries (中國圖書分類法, Lai Classification)

- **Important:** This is **Taiwan/HK/overseas Chinese** system, NOT mainland CLC
- **Based on:** DDC (three-digit Arabic numerals with decimal expansion)
- **LOC code:** "ncsclt" — `http://id.loc.gov/vocabulary/classSchemes/ncsclt`
- **Machine-readable data:** Not found.
- **Action:** Stub service. Separate from CLC. Worth noting for completeness.

### 3e. CCT — Chinese Classified Thesaurus (中国分类主题词表)

- Not a classification system per se — bridges CLC classes with subject headings
- 110,837 preferred terms, 35,690 entry terms
- Web: http://cct.nlc.gov.cn/
- **Action:** Out of scope for this build. Could be future service.

---

## 4. Database Schema (Revised)

```sql
CREATE TABLE classes (
    id TEXT PRIMARY KEY,       -- CLC call number (e.g. "D621.5")
    name TEXT,                 -- Description in Chinese (e.g. "公民权利")
    nameEn TEXT,               -- English label (from Wikimedia Commons, NULL if unavailable)
    edition TEXT,              -- Edition: "5" (future: "4", "3", etc.)
    division TEXT,             -- Top division: "Marxism"|"Philosophy"|"Social Sciences"|
                               --   "Natural Sciences"|"Comprehensive"
    mainClass TEXT,            -- Letter of top-level class (A, B, C, ..., Z)
    broader TEXT,              -- Parent call number (NULL for top-level)
    depth INTEGER,             -- Hierarchy depth (0=division, 1=main class, 2+)
    searchText TEXT            -- Combined: call_number + name + nameEn
)
```

### Type filtering

Use `division` as `type_field`:

| Type ID | Name |
|---------|------|
| `Social Sciences` | Social Sciences (C-K): Politics, Law, Economy, Culture, Literature, etc. |
| `Natural Sciences` | Natural Sciences (N-X): Math, Physics, Biology, Medicine, Engineering, etc. |
| `Philosophy` | Philosophy, Religion (B) |
| `Marxism` | Marxism, Leninism, Mao Zedong Thought (A) |
| `Comprehensive` | General Reference Works (Z) |

---

## 5. Download Strategy (Revised)

### Option A: HuggingFace JSONL (recommended for clean license)

```
https://huggingface.co/datasets/agentlans/library-classification-systems/resolve/main/CLC.jsonl.gz
```

- 8,826 entries, CC BY 4.0
- Gunzipped JSONL, parse with stdlib `json` + `gzip`
- No extra pip deps needed
- Supplement with Wikimedia Commons English labels

### Option B: acdzh GitHub JSON (recommended for completeness)

```
https://raw.githubusercontent.com/acdzh/Chinese-Library-Classification/master/clc.json
```

- 45,785 entries, non-commercial license
- Hierarchical JSON, flatten recursively in `build_db.py`
- No extra pip deps needed

### English Labels (both options)

```
https://commons.wikimedia.org/w/index.php?title=Module:Library_classification_navigation/CLC/CategoryTitleTable.json&action=raw
```

- 4,852 CLC→English mappings, CC BY-SA
- Merge during build: lookup by call number

### Makefile downloads

Two `curl` calls: main data source + English labels. Both cached in `data/`.

---

## 6. Files to Create

### `services/clc/build_db.py`

- Read source (JSONL.gz or hierarchical JSON depending on option chosen)
- If hierarchical JSON: flatten recursively, tracking depth and broader
- Read Wikimedia English labels JSON, build lookup dict
- For each entry:
  - `id` = call_number
  - `name` = description (Chinese)
  - `nameEn` = lookup from Wikimedia (NULL if missing)
  - `edition` = "5"
  - `division` = derived from first letter (A→Marxism, B→Philosophy, C-K→Social Sciences, N-X→Natural Sciences, Z→Comprehensive)
  - `mainClass` = first letter
  - `broader` = parent call number
  - `depth` = hierarchy level
  - `searchText` = f"{call_number} {name} {nameEn or ''}"
- Enable FTS5 on `searchText name nameEn`

### `services/clc/clc.metadata.json`

Standard metadata with `type_field: "division"` and 5 type defaults.

### `services/clc/Makefile`

Follow problemlcsh pattern. Two source downloads (data + English labels). Pip installs: `datasette datasette-reconcile sqlite-utils` (no extra deps for JSONL).

### `services/clc/.gitignore`, `services/clc/README.md`

Standard.

---

## 7. Files to Modify

### Root `Makefile`

- Add `clc` to `SERVICES`
- Add `data-clc` target
- Add to `.PHONY`

### Root `README.md`

- Add endpoint row, build requirements row, data license, type filtering table, references

---

## 8. Open Questions

1. **acdzh (45K entries, non-commercial) vs HuggingFace (8.8K entries, CC BY 4.0)?**
   Non-commercial is fine for this project's use case, but CC BY 4.0 is cleaner.
   Recommendation: Start with HuggingFace, upgrade to acdzh if user prefers completeness over license purity.

2. **English labels:** Include Wikimedia Commons English labels (4,852 entries) as `nameEn` column?
   Recommendation: Yes — makes service usable for non-Chinese-reading users and improves search.

3. **Multi-edition in single DB vs separate DBs?**
   Recommendation: Single DB with `edition` column. Only 5th edition data exists now; column is future-proofing for when 4th edition PDF is parsed.

---

## 9. Build Sequence

1. Create `services/clc/` directory
2. Write `.gitignore`
3. Write `clc.metadata.json`
4. Write `build_db.py`
5. Write `Makefile`
6. Write `README.md`
7. Update root `Makefile`
8. Update root `README.md`
9. Test: `make -C services/clc build && make -C services/clc serve`
10. Verify reconciliation endpoint at `http://127.0.0.1:8001/clc/classes/-/reconcile`

---

## 10. References

- [ISKO Encyclopedia: CLC](https://www.isko.org/cyclo/clc)
- [Wikipedia: Chinese Library Classification](https://en.wikipedia.org/wiki/Chinese_Library_Classification)
- [Baidu Baike: CLC](https://baike.baidu.com/en/item/Chinese%20Library%20Classification/929527)
- [HuggingFace: library-classification-systems](https://huggingface.co/datasets/agentlans/library-classification-systems)
- [GitHub: acdzh/Chinese-Library-Classification](https://github.com/acdzh/Chinese-Library-Classification)
- [Wikimedia Commons: CLC CategoryTitleTable](https://commons.wikimedia.org/wiki/Module:Library_classification_navigation/CLC/CategoryTitleTable.json)
- [Wikidata: Q5100524](https://www.wikidata.org/wiki/Q5100524) / [P1189](https://www.wikidata.org/wiki/Property:P1189)
- [LOC: classSchemes/clc](http://id.loc.gov/vocabulary/classSchemes/clc)
- [BARTOC: CLC](https://bartoc.org/en/node/893)
- [clcindex.com](https://www.clcindex.com/) (Wikidata P1189 formatter)
- [PyPI: chinese-library-classification](https://pypi.org/project/chinese-library-classification/)
