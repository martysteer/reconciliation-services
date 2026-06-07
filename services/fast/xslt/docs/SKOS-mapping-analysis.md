# SKOS Mapping Analysis: FAST Transformation Pipeline

## Executive Summary

This document analyzes the FAST MARCXML → SKOS → CSV/HTML transformation pipeline against:
- **ATHENA D4.2 Guidelines** for SKOSification and terminology mapping
- **mc2skos** MARC21 Authority mapping schema
- **W3C Reconciliation API v0.2** requirements

The current pipeline is well-structured but has several gaps that should be addressed for full compliance with best practices.

---

## 1. Pipeline Overview

```
MARC21 Authority XML (.marcxml)
        ↓
    fast2skos.xsl (Saxon XSLT)
        ↓
    SKOS RDF/XML (.skosxml)
       ↓   ↓   ↓
       ↓   ↓   skos2rhs-html.xsl → Nested HTML vocabulary
       ↓   skos2jstree.py → jsTree bidirectional HTML
       skos2csv-reconcile.xsl → CSV for OpenRefine reconciliation
```

---

## 2. MARC21 to SKOS Mapping Assessment

### 2.1 Current Mappings (fast2skos.xsl)

| MARC Field | Current Mapping | Status |
|------------|-----------------|--------|
| 001 Control Number | `dc:identifier` | ✓ Correct |
| 024 URI | Concept `@rdf:about` | ✓ Correct |
| 1XX Headings | `skos:prefLabel` | ✓ Correct |
| 4XX See From | `skos:altLabel` | ✓ Correct |
| 5XX See Also ($w=g) | `skos:broader` | ✓ Correct |
| 5XX See Also ($w=h) | `skos:narrower` | ✓ Correct |
| 5XX See Also (default) | `skos:related` | ✓ Correct |
| 7XX Linking | `skos:closeMatch` | ✓ Correct |
| 043 Geographic Code | `dc:coverage` | ✓ Correct |
| 046 Dates | `schema:temporalCoverage` | ✓ Correct |
| 680 Scope Note | `skos:scopeNote` | ✓ Correct |
| 688 Application Note | `skos:editorialNote` | ✓ Correct |

### 2.2 Missing Mappings (per mc2skos + ATHENA)

| MARC Field | Recommended Mapping | Priority | Notes |
|------------|---------------------|----------|-------|
| 005 Transaction Date | `dcterms:modified` | HIGH | Essential for versioning |
| 008[0:6] Date Entered | `dcterms:created` | HIGH | Provenance tracking |
| 008[8] = "d" or "e" | `owl:deprecated` | HIGH | Invalid/obsolete headings |
| 667 Nonpublic Note | `skos:editorialNote` | MEDIUM | Administrative notes |
| 670 Source Data | `skos:note` | LOW | Reference documentation |
| 677 Definition | `skos:definition` | HIGH | Per ATHENA: distinct from scopeNote |
| 678 Biographical | `skos:note` | LOW | Person/org background |
| 681 Subject Example | `skos:example` | MEDIUM | Usage examples |
| 682 Deleted Info | `skos:changeNote` | MEDIUM | Track deletions |
| 685 History Note | `skos:historyNote` | MEDIUM | Diachronic evolution |

### 2.3 ATHENA Format Compliance Assessment

The ATHENA Format specifies mandatory and optional elements. Current status:

| ATHENA Requirement | Current Status | Gap |
|--------------------|----------------|-----|
| **skos:Concept** | ✓ Implemented | None |
| **skos:ConceptScheme** | ✓ Implemented | None |
| **skos:inScheme** | ✓ Implemented | None |
| **skos:prefLabel (mandatory)** | ✓ Per concept | None |
| xml:lang attribute | ✓ Using "en" | Could add other langs |
| skos:altLabel | ✓ From 4XX | None |
| skos:hiddenLabel | ✗ Not mapped | Map from 4XX $w=nnea? |
| skos:notation | ✗ Not mapped | Add for code-based IDs |
| skos:broader/narrower | ✓ From 5XX | None |
| skos:related | ✓ From 5XX | None |
| skos:Collection | ✗ Not implemented | Could group by facet |
| skos:definition | ✗ Not mapped | Map from 677 |
| skos:scopeNote | ✓ From 680 | None |
| skos:historyNote | ✗ Not mapped | Map from 685 |
| skos:changeNote | ✗ Not mapped | Map from 682 |
| skos:editorialNote | ✓ From 688 | Add 667 |
| skos:example | ✗ Not mapped | Map from 681 |

---

## 3. Specific Recommendations

### 3.1 Add Missing Date/Status Mappings

The 005 and 008 fields contain critical metadata per mc2skos and ATHENA:

```xml
<!-- 005: Date and time of latest transaction → dcterms:modified -->
<dcterms:modified>
  <xsl:call-template name="format-marc-datetime">
    <xsl:with-param name="raw" select="mx:controlfield[@tag='005']"/>
  </xsl:call-template>
</dcterms:modified>

<!-- 008[0:6]: Date entered on file → dcterms:created -->
<dcterms:created>
  <xsl:call-template name="format-marc-date">
    <xsl:with-param name="raw" select="substring(mx:controlfield[@tag='008'], 1, 6)"/>
  </xsl:call-template>
</dcterms:created>

<!-- 008[8]: Classification validity - 'd' or 'e' = deprecated -->
<xsl:if test="substring(mx:controlfield[@tag='008'], 9, 1) = 'd' or 
              substring(mx:controlfield[@tag='008'], 9, 1) = 'e'">
  <owl:deprecated rdf:datatype="http://www.w3.org/2001/XMLSchema#boolean">true</owl:deprecated>
</xsl:if>
```

### 3.2 Add skos:notation for FAST Identifiers

Per ATHENA guidelines, notation should be used for codes distinct from natural language labels:

```xml
<!-- The FAST ID as notation (fst code) -->
<skos:notation rdf:datatype="http://id.worldcat.org/fast/ontology/FASTId">
  <xsl:value-of select="$rawId"/>
</skos:notation>
```

### 3.3 Add skos:Collection for Facet Types

ATHENA recommends collections for thematic groupings. FAST facets are ideal:

```xml
<skos:Collection rdf:about="http://id.worldcat.org/fast/facet/Topical">
  <skos:prefLabel xml:lang="en">FAST Topical Terms</skos:prefLabel>
  <skos:member rdf:resource="..."/>
</skos:Collection>
```

### 3.4 Map Additional Note Types

Per mc2skos, specific 6XX fields should map to distinct SKOS properties:

| MARC | SKOS Property | Implementation |
|------|---------------|----------------|
| 677 Definition | skos:definition | Add template |
| 681 Subject Example | skos:example | Add template |
| 682 Deleted Heading | skos:changeNote | Add template |
| 685 History Note | skos:historyNote | Add template |

---

## 4. CSV Output Assessment (skos2csv-reconcile.xsl)

### 4.1 W3C Reconciliation API Alignment

The CSV output targets OpenRefine reconciliation. Per the W3C Reconciliation API v0.2:

| API Requirement | CSV Column | Status |
|-----------------|------------|--------|
| Entity ID | `id` | ✓ |
| Entity Name | `name` | ✓ |
| Entity Type | `type` | ✓ (facet) |
| Description | `description` | ✓ (scopeNote) |

### 4.2 Recommended CSV Enhancements

Add columns for enhanced reconciliation:

```
id,uri,name,searchText,type,description,altLabels,broader,narrower,
related,closeMatch_notation,closeMatch_label,temporalCoverage,coverage,
deprecated,created,modified
```

---

## 5. HTML Output Assessment

### 5.1 RHS Vocabulary HTML (skos2rhs-html.xsl)

Current implementation correctly handles:
- Nested hierarchy via broader/narrower
- Term, usedFor, relatedTerm spans
- ID extraction from URIs

### 5.2 jsTree HTML (skos2jstree.py)

The Python script properly:
- Normalizes inconsistent FAST URIs
- Builds bidirectional hierarchy
- Handles broader/narrower relationships

---

## 6. Updated XSLT Recommendations

The following sections provide updated transform code incorporating all recommendations.
