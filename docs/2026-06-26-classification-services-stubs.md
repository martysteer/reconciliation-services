# Classification System Reconciliation Services — Stubs

Future reconciliation services for library/knowledge classification systems beyond the main CLC build. Each stub documents what's known about data availability, structure, and feasibility.

Status legend: **Ready** (data source identified, buildable now), **Feasible** (data exists but needs work), **Research** (no machine-readable data found yet), **Blocked** (no data source known)

---

## Chinese Classification Systems

### CASLC — Chinese Academy of Sciences Library Classification (科图法)

- **Status:** Research
- **Service name:** `caslc`
- **Structure:** 5 divisions, 25 main classes, pure Arabic numerals (00-90)
- **Editions:** 1st (1958), 2nd (1974-82), 3rd (1994, ISBN 7030037820)
- **Publisher:** Science Press (科学出版社)
- **Current usage:** CAS and CASS libraries. Largely superseded by CLC.
- **Known 25 classes:**

| Code | Subject |
|------|---------|
| 00 | Marxism-Leninism, Mao Zedong Thought |
| 10 | Philosophy |
| 20 | General Social Sciences |
| 21 | History |
| 27 | Economics |
| 31 | Politics, Social Life |
| 34 | Law, Jurisprudence |
| 36 | Military Science |
| 37 | Culture, Science, Education, Sports |
| 41 | Language, Linguistics |
| 42 | Literature |
| 48 | Art |
| 49 | Atheism, Religious Studies |
| 50 | General Natural Sciences |
| 51 | Mathematics |
| 52 | Mechanics |
| 53 | Physics |
| 54 | Chemistry |
| 55 | Astronomy |
| 56 | Earth Sciences |
| 58 | Biological Sciences |
| 61 | Medicine, Public Health |
| 71 | Engineering Technology |
| 72 | (possibly Energy Science / Power Engineering) |
| 90 | Comprehensive Works |

- **Data sources found:** None machine-readable. Digital version reportedly at CAS Literature and Information Center (https://www.las.ac.cn/) but not openly downloadable. Top-level classes available from Southwest Petroleum University Library site.
- **Path forward:** Hardcode the 25 top-level classes as minimal service. Investigate CAS library contacts for structured data. Check if `sheoguo` pip package or similar has CASLC data.
- **References:**
  - [Baidu Baike: 科图法](https://baike.baidu.com/item/%E4%B8%AD%E5%9B%BD%E7%A7%91%E5%AD%A6%E9%99%A2%E5%9B%BE%E4%B9%A6%E9%A6%86%E5%9B%BE%E4%B9%A6%E5%88%86%E7%B1%BB%E6%B3%95/6273783)
  - [SWPU Library: CASLC classes](https://lib.swpu.edu.cn/1858.80/clc/slc.html)

---

### RUCLC — Renmin University Library Classification (人大法)

- **Status:** Blocked
- **Service name:** `ruclc`
- **Structure:** 4 divisions, 17 main classes, Arabic numerals
- **Created:** 1953 — China's first post-1949 library classification
- **Editions:** 1953, 1954, 1955, 1962, 1982, 1996 (6 editions)
- **Based on:** Soviet public library decimal classification
- **Current usage:** Abandoned. Renmin University itself converted to CLC (completed 2011 for post-1995 books).
- **4 divisions:** General/Summary Sciences, Social Sciences, Natural Sciences, Comprehensive Works
- **Data sources found:** None. The complete 17-class list has not been found in online sources. Would need original print publication.
- **Path forward:** Historical interest only. If 17-class list is located, can hardcode as minimal service.
- **References:**
  - [Baidu Baike: 人大法](https://baike.baidu.com/item/%E4%B8%AD%E5%9B%BD%E4%BA%BA%E6%B0%91%E5%A4%A7%E5%AD%A6%E5%9B%BE%E4%B9%A6%E9%A6%86%E5%9B%BE%E4%B9%A6%E5%88%86%E7%B1%BB%E6%B3%95/12681074)

---

### NCSCL — New Classification Scheme for Chinese Libraries (中國圖書分類法, Lai Classification)

- **Status:** Research
- **Service name:** `ncscl`
- **Important:** This is the **Taiwan/Hong Kong/overseas Chinese** system, NOT the mainland CLC
- **Creator:** Lai Yung-hsiang (賴永祥), starting 1956, 1st edition 1964
- **Based on:** Liu Guojun's 1929 system, itself based on DDC
- **Notation:** Pure three-digit Arabic numerals with decimal expansion (DDC-style)
- **Usage:** Libraries in Taiwan, pre-1997 Hong Kong, Macau, Singapore (Chinese collections)
- **LOC code:** "ncsclt" — http://id.loc.gov/vocabulary/classSchemes/ncsclt
- **Data sources found:** None machine-readable. No known open dataset.
- **Path forward:** Investigate Taiwan national library sources. May have structured data available.
- **References:**
  - [Wikipedia: New Classification Scheme for Chinese Libraries](https://en.wikipedia.org/wiki/New_Classification_Scheme_for_Chinese_Libraries)
  - [LOC: ncsclt](http://id.loc.gov/vocabulary/classSchemes/ncsclt)

---

### CCT — Chinese Classified Thesaurus (中国分类主题词表)

- **Status:** Research
- **Service name:** `cct` (if built)
- **Not a classification system** — bridges CLC classes with subject headings (thesaurus)
- **Scale:** 110,837 preferred terms, 35,690 entry terms, 60,000+ pre-coordinated headings
- **Web:** http://cct.nlc.gov.cn/ (launched 2009, updated 2014 for CLC 5th ed.)
- **BARTOC:** https://bartoc.org/en/node/20314
- **SKOS pilot:** Some data converted to SKOS in research projects, not publicly available
- **Path forward:** Out of scope for classification services. Could be separate thesaurus reconciliation service.

---

## Other Classification Systems (from HuggingFace Dataset)

The `agentlans/library-classification-systems` HuggingFace dataset includes 5 other systems besides CLC. Each could become a reconciliation service with minimal effort since the data is already structured.

### DDC — Dewey Decimal Classification

- **Status:** Feasible (data exists, license question)
- **Service name:** `ddc`
- **HuggingFace entries:** 1,110 (outline level)
- **License:** CC BY 4.0 on HuggingFace dataset, but DDC itself is copyrighted by OCLC
- **Structure:** 10 main classes (000-900), 100 divisions, 1000 sections
- **Notation:** Three-digit Arabic numerals with decimal expansion
- **Concern:** OCLC holds copyright on DDC. The HuggingFace data is outline-level only (freely published by OCLC), so likely acceptable. Verify.
- **Path forward:** Buildable from HuggingFace data. Small but useful for reconciliation.

### LCC — Library of Congress Classification

- **Status:** Feasible
- **Service name:** `lcc`
- **HuggingFace entries:** 6,517 (outline level)
- **License:** CC BY 4.0 on HuggingFace dataset. LCC outlines are public domain (US government work).
- **Structure:** 21 main classes (A-Z), letter-number notation
- **Path forward:** Buildable from HuggingFace data. LOC also publishes outlines directly.

### UDC — Universal Decimal Classification

- **Status:** Feasible (data exists, license question)
- **Service name:** `udc`
- **HuggingFace entries:** 2,431
- **License:** CC BY 4.0 on dataset. UDC itself managed by UDC Consortium.
- **Structure:** 10 main classes (0-9), faceted notation
- **Note:** This is what some Chinese sources call "国际统一图书分类法" (International Integrated Book Classification)
- **Path forward:** Buildable. Verify UDC Consortium position on open outline data.

### RVK — Regensburger Verbundklassifikation

- **Status:** Feasible
- **Service name:** `rvk`
- **HuggingFace entries:** 5,032
- **License:** CC BY 4.0 on dataset
- **Language:** German
- **Structure:** Used across German universities
- **Path forward:** Buildable. Niche audience.

### BBK — Library-Bibliographic Classification (Библиотечно-библиографическая классификация)

- **Status:** Feasible
- **Service name:** `bbk`
- **HuggingFace entries:** 2,588
- **License:** CC BY 4.0 on dataset
- **Language:** Russian
- **Structure:** Soviet/Russian national classification
- **Path forward:** Buildable. Niche audience.

---

## African Classification Systems

*(Placeholder — user has a list of African continental classification systems to add)*

### [TBD] — African classification systems

- **Status:** Awaiting user input
- **Notes:** User will provide a list of classification systems from the African continental perspective. Stubs will be expanded once details are provided.
- **Considerations:**
  - Check BARTOC.org for registered African KOS (Knowledge Organization Systems)
  - Check if any African national libraries publish classification data openly
  - Check LOC `classSchemes` vocabulary for African-origin schemes
  - Consider multilingual support needs (French, Portuguese, Arabic, Swahili, Amharic, etc.)

---

## Batch Build Strategy

If building multiple classification services from the HuggingFace dataset, consider a **shared build pattern:**

1. Single download of `agentlans/library-classification-systems` (all configs)
2. Per-service `build_db.py` that filters to its config (CLC, DDC, LCC, etc.)
3. Or: one `build_db.py` with a config argument

This avoids duplicating download logic across 6 services. Could implement as:

```
services/libclass/
  build_db.py --system CLC --db data/clc.db
  build_db.py --system DDC --db data/ddc.db
  ...
```

Or keep each service self-contained (current project pattern). User preference.

---

## Priority Order (Suggested)

1. **CLC** — primary request, most data available, largest user base
2. **LCC** — clean license, large dataset, widely used internationally
3. **DDC** — most globally used classification, but copyright concerns
4. **UDC** — international standard, relevant to "International Integrated Book Classification" question
5. **CASLC** — Chinese system, limited data
6. **African systems** — pending user input
7. **BBK, RVK** — niche audiences
8. **NCSCL, RUCLC** — limited/no data available
