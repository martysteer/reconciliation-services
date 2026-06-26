# CLC (Chinese Library Classification) Reconciliation Service

W3C Reconciliation API endpoint for the Chinese Library Classification (中国图书馆分类法 / 中图法), China's national library classification system. 5th edition, ~45K categories with bilingual (Chinese + English) search.

## Build & Run

```bash
make build     # Setup venv + download data + build database
make serve     # Start on http://127.0.0.1:8001/clc/classes/-/reconcile
make status    # Show file sizes and row count
```

## Type Filtering

Filter by division using the `type` parameter in OpenRefine:

| Division | Main Classes | Description |
|----------|-------------|-------------|
| Social Sciences | C-K | Politics, Law, Economics, Education, etc. |
| Natural Sciences | N-X | Math, Physics, Engineering, Medicine, etc. |
| Philosophy | B | Philosophy, Religion, Psychology |
| Marxism | A | Works of Marx, Engels, Lenin, Mao, Deng |
| Comprehensive | Z | Encyclopedias, Bibliographies, General Works |

## Data Sources

- **Classification hierarchy** (45,785 entries): [acdzh/Chinese-Library-Classification](https://github.com/acdzh/Chinese-Library-Classification) — non-commercial license
- **English labels** (4,851 bilingual mappings): [Wikimedia Commons CLC CategoryTitleTable](https://commons.wikimedia.org/wiki/Module:Library_classification_navigation/CLC/CategoryTitleTable.json) — CC BY-SA
