# Classification System Reconciliation Services — Stubs

Future reconciliation services for library/knowledge classification systems beyond the main CLC build. Each stub documents what's known about data availability, structure, and feasibility.

Status legend: **Ready** (data source identified, buildable now), **Feasible** (data exists but needs work), **Research** (no machine-readable data found yet), **Blocked** (no data source known)

---

## Global / International Classification Systems

### DDC — Dewey Decimal Classification

- **Status:** Ready
- **Service name:** `ddc`
- **Creator:** Melvil Dewey, 1876
- **Structure:** 10 main classes (000-900), 100 divisions, 1000 sections, decimal expansion
- **Usage:** Most widely used classification globally. Standard in public and school libraries worldwide, including across Africa.
- **Data sources:**
  - **HuggingFace:** 1,110 entries (summaries/outline, top 3 levels). CC BY 4.0. `agentlans/library-classification-systems` config `DDC`.
  - **OCLC DDC Summaries PDF:** https://www.oclc.org/content/dam/oclc/dewey/resources/summaries/deweysummaries.pdf — 10+100+1000 entries, freely published
  - **Dewey Linked Data:** https://entities.oclc.org/worldcat/ddc — base set (top 3 levels) in RDF/SKOS, free access. Full data requires WebDewey subscription.
  - **dewey.info:** Historical linked data URIs like `http://dewey.info/class/{number}/e23/` — may be superseded by entities.oclc.org
- **License concern:** DDC is copyrighted by OCLC. Summaries (top 3 levels) are freely published and redistributable. Full schedules require WebDewey subscription ($325+/yr).
- **Path forward:** Build from HuggingFace JSONL (1,110 entries). Supplement with OCLC linked data if richer data needed. Outline level is sufficient for reconciliation.
- **Wikidata:** Q48460
- **BARTOC:** https://bartoc.org/en/node/241
- **References:**
  - [OCLC Dewey](https://www.oclc.org/en/dewey.html)
  - [HuggingFace dataset](https://huggingface.co/datasets/agentlans/library-classification-systems)

---

### LCC — Library of Congress Classification

- **Status:** Ready
- **Service name:** `lcc`
- **Creator:** Library of Congress, 1897
- **Structure:** 21 main classes (A-Z), letter-number notation
- **Usage:** Academic and research libraries worldwide, especially North America.
- **Data sources:**
  - **HuggingFace:** 6,517 entries (outline level). CC BY 4.0.
  - **LOC Free PDFs:** All 44 schedules as print-ready PDFs at https://www.loc.gov/aba/publications/FreeLCC/freelcc.html (PDF only, not structured)
  - **LOC Linked Data:** Only 4 classes (B, M, N, Z) available as RDF at `http://id.loc.gov/authorities/classification/{number}`. NOT available in bulk download.
  - **LCC Outline (HTML):** https://www.loc.gov/catdir/cpso/lcco/
- **License:** LCC outlines are public domain (US government work). HuggingFace dataset CC BY 4.0.
- **Path forward:** Build from HuggingFace JSONL (6,517 entries). Best-licensed, largest outline dataset.
- **Wikidata:** Q621080
- **BARTOC:** https://bartoc.org/en/node/486
- **References:**
  - [LOC Classification](https://www.loc.gov/catdir/cpso/lcc.html)
  - [LOC Free LCC PDFs](https://www.loc.gov/aba/publications/FreeLCC/freelcc.html)

---

### UDC — Universal Decimal Classification

- **Status:** Ready
- **Service name:** `udc`
- **Creators:** Paul Otlet & Henri La Fontaine, 1905 (based on DDC)
- **Structure:** 10 main classes (0-9, class 4 vacant), faceted notation with auxiliary tables
- **Usage:** International. Widely used in Europe, South America, parts of Africa. Known in Chinese contexts as 国际统一图书分类法 (International Integrated Book Classification).
- **Main classes:**

| Class | Subject |
|-------|---------|
| 0 | Science & Knowledge, Computer Science, Information |
| 1 | Philosophy, Psychology |
| 2 | Religion, Theology |
| 3 | Social Sciences |
| 4 | (Vacant) |
| 5 | Mathematics, Natural Sciences |
| 6 | Applied Sciences, Medicine, Technology |
| 7 | Arts, Recreation, Entertainment, Sport |
| 8 | Language, Linguistics, Literature |
| 9 | Geography, Biography, History |

- **Data sources:**
  - **HuggingFace:** 2,431 entries. CC BY 4.0. From ROSSIO UDC Summary (MRF 2011).
  - **ROSSIO SKOS:** ~2,600 classes, downloadable as RDF/XML and Turtle. CC BY-SA 3.0. https://vocabs.rossio.fcsh.unl.pt/pub/udcS/en/
  - **Finto SKOS:** Trilingual (Finnish, Swedish, English) UDC Summary. https://finto.fi/udcs/en/ — REST API available.
  - **udcdata.info:** Currently unavailable pending MRF12 revision. Was the primary linked data endpoint since 2011.
  - **Full MRF:** 70,000+ classes. Licensed from UDC Consortium (paid, case-by-case).
- **License:** Summary (~2,600 classes) freely available. Full MRF is licensed/paid.
- **Path forward:** Build from HuggingFace JSONL or ROSSIO SKOS. Summary level is good for reconciliation. ROSSIO SKOS has richer data (multilingual labels, hierarchy).
- **Wikidata:** Q219919
- **BARTOC:** https://bartoc.org/en/node/496
- **References:**
  - [UDC Consortium](https://udcc.org/)
  - [ROSSIO UDC Summary](https://vocabs.rossio.fcsh.unl.pt/pub/udcS/en/)
  - [Finto UDC Summary](https://finto.fi/udcs/en/)

---

### CC — Colon Classification

- **Status:** Research
- **Service name:** `cc`
- **Creator:** S. R. Ranganathan, 1933 (India)
- **Editions:** 7 editions (1933, 1939, 1950, 1952, 1957, 1960/63, 1987 posthumous)
- **Structure:** Faceted classification using PMEST (Personality, Matter, Energy, Space, Time). ~42 main classes using mixed notation (Roman caps, lowercase, Arabic numerals, Greek delta).
- **Usage:** India primarily. Influential as the foundation of faceted classification theory.
- **Known main classes (CC-7):**

| Notation | Subject |
|----------|---------|
| z | Generalia |
| 1 | Universe of Knowledge |
| 2 | Library Science |
| 3 | Book Science |
| 4 | Journalism |
| B | Mathematics |
| C | Physics |
| D | Engineering |
| E | Chemistry |
| F | Technology |
| G | Biology |
| H | Geology |
| I | Botany |
| J | Agriculture |
| K | Zoology |
| L | Medicine |
| M | Useful Arts |
| Δ | Spiritual Experience & Mysticism |
| N | Fine Arts |
| O | Literature |
| P | Linguistics |
| Q | Religion |
| R | Philosophy |
| S | Psychology |
| T | Education |
| U | Geography |
| V | History |
| W | Political Science |
| X | Economics |
| Y | Sociology |
| Z | Law |

- **Data sources:**
  - **Archive.org:** Scanned 2nd edition (1939, 778 pages, OCR'd): https://archive.org/details/in.ernet.dli.2015.279875
  - **CINDEX (2002):** Machine-readable CC-7 index on CD-ROM (UNESCO WinISIS format). Obsolete.
  - **CCLitBox:** Wikidata gadget for auto-generating CC class numbers for Literature (Class O only). Source: https://zenodo.org/record/5090640
  - **No JSON/CSV/SKOS/RDF exists** for the full classification.
- **Wikidata:** Q1110558, Property P8248
- **BARTOC:** https://bartoc.org/en/node/862
- **Path forward:** Most difficult system to digitize. Would require OCR extraction from Archive.org scans or manual entry of the ~42 main classes + key subdivisions. The faceted nature (synthetic class numbers) means a static list is inherently incomplete — CC generates class numbers algorithmically.
- **References:**
  - [Wikipedia: Colon Classification](https://en.wikipedia.org/wiki/Colon_classification)
  - [ISKO: Colon Classification](https://www.isko.org/cyclo/colon_classification)
  - [Archive.org: CC 2nd edition](https://archive.org/details/in.ernet.dli.2015.279875)

---

### BBC — Bliss Bibliographic Classification (BC2)

- **Status:** Feasible
- **Service name:** `bbc`
- **Creator:** Henry E. Bliss, 1st edition 1940. BC2 (2nd edition) maintained by Bliss Classification Association (BCA).
- **Structure:** Single and double letter classes. ~23 planned volumes, 14 published so far.
- **Usage:** ~19 UK libraries (Cambridge/Oxford colleges, specialist libraries).
- **Main classes (BC2 outline):**

| Class | Subject |
|-------|---------|
| 2/9 | Generalia, Phenomena, Knowledge, Information Science |
| A/AL | Philosophy & Logic |
| AM/AX | Mathematics, Probability, Statistics |
| AY/B | General Science, Physics |
| C | Chemistry, Chemical Engineering |
| D | Space & Earth Sciences |
| E/GQ | Biological Sciences |
| GR | Agriculture |
| GU | Veterinary Science |
| GY | Applied Ecology |
| H | Physical Anthropology, Human Biology, Health Sciences |
| I | Psychology & Psychiatry |
| J | Education |
| K | Society (Social Sciences) |
| L/O | History (incl. Archaeology, Biography, Travel) |
| P | Religion, Occult, Morals and Ethics |
| Q | Social Welfare & Criminology |
| R | Politics & Public Administration |
| S | Law |
| T | Economics & Management |
| U/V | Technology, Engineering, Recreation |
| W | The Arts |
| WP | Music |
| X/Y | Language, Literature |

- **Data sources:**
  - **BCA source code:** Uniquely formatted text files for each schedule. Custom format: notation, indent level, labels, facet markers, notes. Parser not publicly available.
  - **Draft schedules:** Downloadable as PDF/DOC from https://www.blissclassification.org.uk/bcsched.shtml (not structured data).
  - **SKOS conversion (Code4Lib):** Queens' College Cambridge converted BC2 schedules to SKOS RDF using Python RDFLib. Documented at https://journal.code4lib.org/articles/18073. **Data not yet published online.**
  - **No JSON/CSV/SKOS download** currently available.
- **License:** Published schedules are copyright BCA (De Gruyter Brill publishes).
- **Wikidata:** Q1114454
- **BARTOC:** https://bartoc.org/en/node/462
- **Path forward:** Contact BCA or Queens' College Cambridge librarian about the SKOS RDF conversion. The Code4Lib article provides a complete roadmap for parsing BC2 source code. Could hardcode the ~24 main classes as minimal service.
- **References:**
  - [BCA website](https://www.blissclassification.org.uk/)
  - [Code4Lib: Converting Bliss to SKOS](https://journal.code4lib.org/articles/18073)
  - [ISKO: BC2](https://www.isko.org/cyclo/bc2)
  - [BCA Schedules](https://www.blissclassification.org.uk/bcsched.shtml)

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

- **Data sources found:** None machine-readable. Digital version reportedly at CAS Literature and Information Center (https://www.las.ac.cn/) but not openly downloadable. Top-level classes from Southwest Petroleum University Library site.
- **Path forward:** Hardcode 25 top-level classes as minimal service. Investigate CAS library contacts for structured data.
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
- **Current usage:** Abandoned. Renmin University itself converted to CLC (completed 2011).
- **Data sources found:** None. Complete 17-class list not found in online sources.
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
- **Data sources found:** None machine-readable.
- **Path forward:** Investigate Taiwan National Library sources.
- **References:**
  - [Wikipedia: NCSCL](https://en.wikipedia.org/wiki/New_Classification_Scheme_for_Chinese_Libraries)
  - [LOC: ncsclt](http://id.loc.gov/vocabulary/classSchemes/ncsclt)

---

### CCT — Chinese Classified Thesaurus (中国分类主题词表)

- **Status:** Research
- **Service name:** `cct` (if built)
- **Not a classification system** — bridges CLC classes with subject headings (thesaurus)
- **Scale:** 110,837 preferred terms, 35,690 entry terms, 60,000+ pre-coordinated headings
- **Web:** http://cct.nlc.gov.cn/ (launched 2009, updated 2014 for CLC 5th ed.)
- **BARTOC:** https://bartoc.org/en/node/20314
- **Path forward:** Out of scope for classification services. Could be separate thesaurus reconciliation service.

---

## African Continental Perspective

The African Library Foundation (ALF) identifies DDC, LCC, UDC, CC, and BBC as the top 5 classification systems relevant to African libraries. These are all Western/international systems — no Africa-specific classification system has been developed at a continental level, though there is active discussion about this need.

### Context: Decolonizing Knowledge Organization in Africa

- Existing Western classification systems inadequately represent African knowledge contexts (e.g., DDC/LCC treat Egyptian literature under "Oriental languages" rather than African literature)
- Calls for African-originated standards and an African continental bureau to liaise with IFLA/LC
- Indigenous African knowledge systems were historically oral, creating unique challenges for integration into formal classification
- The AU Library (African Union) maintains a collection using standard international systems
- **No Africa-specific classification system** with machine-readable data has been identified. The ALF's "Top 5" are DDC, LCC, UDC, CC, and BBC — all covered above.

### AU Library Reference Collection

- **URL:** https://library.au.int/fr/libraries-classification-systems
- **Content:** Bibliography of classification theory texts (Sayers 1970, Johnson 1968, Batty 1966/1971, Maltby 1972). Reference collection, not a classification system.

### Potential African KOS to Investigate

- Check BARTOC.org for African-registered Knowledge Organization Systems
- Check national libraries: South Africa (NLSA), Nigeria (NLN), Kenya (KNLS), Egypt (BnF/Dar al-Kutub)
- Check if any African university libraries have developed local classification extensions
- AU/ACALAN linguistic classification of African languages may be relevant
- Consider: African subject heading lists, African name authority files as adjacent reconciliation services

### User's African Systems List

*(Awaiting additional details from user — they mentioned having a list of classification systems from the African continental perspective beyond the ALF "Top 5")*

---

## Other Regional Systems

### RVK — Regensburger Verbundklassifikation

- **Status:** Ready
- **Service name:** `rvk`
- **HuggingFace entries:** 5,032
- **License:** CC BY 4.0 on dataset
- **Language:** German
- **Structure:** Used across German universities
- **Path forward:** Buildable from HuggingFace data. Niche audience.

### BBK — Library-Bibliographic Classification (Библиотечно-библиографическая классификация)

- **Status:** Ready
- **Service name:** `bbk`
- **HuggingFace entries:** 2,588
- **License:** CC BY 4.0 on dataset
- **Language:** Russian
- **Structure:** Soviet/Russian national classification
- **Path forward:** Buildable from HuggingFace data. Niche audience.

---

## Batch Build Strategy

Multiple systems from the HuggingFace `agentlans/library-classification-systems` dataset can share a build pattern:

**Option A — Shared builder (one service, multiple DBs):**
```
services/libclass/
  build_db.py --system CLC --db data/clc.db
  build_db.py --system DDC --db data/ddc.db
  build_db.py --system LCC --db data/lcc.db
  build_db.py --system UDC --db data/udc.db
  build_db.py --system RVK --db data/rvk.db
  build_db.py --system BBK --db data/bbk.db
```

**Option B — Self-contained services (current project pattern):**
Each system gets its own `services/{name}/` directory with independent Makefile, build_db.py, metadata. Duplicates download logic but matches existing architecture.

User preference needed.

---

## Feasibility Summary

| System | Status | Entries Available | License | Effort |
|--------|--------|-------------------|---------|--------|
| **CLC** | Ready | 8,826 (HF) or 45,785 (GitHub) | CC BY 4.0 / Non-commercial | Low |
| **DDC** | Ready | 1,110 | CC BY 4.0 (summaries) | Low |
| **LCC** | Ready | 6,517 | CC BY 4.0 / Public domain | Low |
| **UDC** | Ready | 2,431 (HF) or ~2,600 (SKOS) | CC BY 4.0 / CC BY-SA 3.0 | Low |
| **RVK** | Ready | 5,032 | CC BY 4.0 | Low |
| **BBK** | Ready | 2,588 | CC BY 4.0 | Low |
| **BBC** | Feasible | ~24 main classes (outline) | Copyright BCA | Medium (contact BCA for SKOS data) |
| **CC** | Research | ~42 main classes (manual) | Public domain (1933+) | High (no structured data) |
| **CASLC** | Research | 25 main classes (known) | Unknown | Medium (hardcode top-level) |
| **NCSCL** | Research | Unknown | Unknown | Unknown |
| **RUCLC** | Blocked | 0 | Unknown | Blocked |
| **African** | Pending | TBD | TBD | TBD |

---

## Priority Order (Suggested)

1. **CLC** — primary request, most data, largest user base in China
2. **DDC** — most globally used, relevant to African libraries (ALF #1)
3. **LCC** — clean license, large dataset, ALF #2
4. **UDC** — international standard, ALF #3, also "International Integrated Book Classification"
5. **CC** — ALF #4, historically important, but data-limited
6. **BBC** — ALF #5, SKOS conversion exists (unpublished)
7. **RVK, BBK** — regional systems, easy to build
8. **CASLC** — Chinese system, limited data
9. **African systems** — pending user input
10. **NCSCL, RUCLC** — limited/no data

---

## References (Global)

- [African Library Foundation (ALF)](https://www.facebook.com/profile.php?id=100064034655327)
- [AU Library Classification Collection](https://library.au.int/fr/libraries-classification-systems)
- [BARTOC.org](https://bartoc.org/) — Registry of Knowledge Organization Systems
- [HuggingFace: library-classification-systems](https://huggingface.co/datasets/agentlans/library-classification-systems)
- [ISKO Encyclopedia of Knowledge Organization](https://www.isko.org/cyclo/)
- [LOC Classification Schemes vocabulary](http://id.loc.gov/vocabulary/classSchemes)
- [Decolonizing Knowledge Organization (ResearchGate)](https://www.researchgate.net/publication/396675615_Decolonizing_Knowledge_Organization_Indigenous_Knowledge_Systems_in_Library_Classification)
