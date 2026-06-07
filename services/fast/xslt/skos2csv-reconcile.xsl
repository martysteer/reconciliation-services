<?xml version="1.0" encoding="UTF-8"?>
<!--
  SKOS to CSV Transformation for Reconciliation
  
  Converts SKOS/RDF concepts to flat CSV format suitable for:
  - sqlite-utils import
  - datasette-reconcile plugin
  - OpenRefine reconciliation
  
  Input:  SKOS/RDF XML file (from fast2skos.xsl)
  Output: CSV with columns for reconciliation
  
  Parameters:
    facetType - The FAST facet type (passed through for 'type' column)
  
  Output columns:
    id              - FAST identifier (fst code)
    uri             - Full URI
    name            - Preferred label
    searchText      - Combined prefLabel + altLabels + notation for fuzzy matching
    type            - Facet type
    description     - Scope note
    altLabels       - Pipe-separated alternate labels
    broader         - Broader term URIs (pipe-separated)
    narrower        - Narrower term URIs (pipe-separated)
    related         - Related term URIs (pipe-separated)
    closeMatch_notation - LCSH identifier
    closeMatch_label    - LCSH heading
    temporalCoverage    - Date range
    coverage            - Geographic area code
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:schema="http://schema.org/"
    xmlns:fast="http://id.worldcat.org/fast/ontology/">

  <xsl:output method="text" encoding="UTF-8"/>
  
  <xsl:variable name="sep" select="','"/>
  <xsl:variable name="multisep" select="'|'"/>
  <xsl:variable name="nl" select="'&#10;'"/>

  <xsl:template match="/">
    <!-- Header row -->
    <xsl:text>id,uri,name,searchText,type,description,altLabels,broader,narrower,related,closeMatch_notation,closeMatch_label,temporalCoverage,coverage</xsl:text>
    <xsl:value-of select="$nl"/>
    
    <xsl:for-each select="//skos:Concept[@rdf:about]">
      <xsl:call-template name="process-concept"/>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="process-concept">
    <!-- id -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="dc:identifier"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- uri -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="@rdf:about"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- name (prefLabel) -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="skos:prefLabel"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- searchText: prefLabel + altLabels + notations for fuzzy/exact search (D4.2 notation support) -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:value-of select="skos:prefLabel"/>
        <xsl:for-each select="skos:altLabel">
          <xsl:text> </xsl:text>
          <xsl:value-of select="."/>
        </xsl:for-each>
        <xsl:for-each select="skos:notation">
          <xsl:text> </xsl:text>
          <xsl:value-of select="."/>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- type (facet) -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="fast:facet"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- description (scopeNote if present) -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="skos:scopeNote"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- altLabels (pipe-separated) -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:altLabel">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- broader -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:broader/@rdf:resource">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- narrower -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:narrower/@rdf:resource">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- related -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:related/@rdf:resource">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- closeMatch_notation -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:closeMatch/skos:Concept/skos:notation">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- closeMatch_label -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value">
        <xsl:for-each select="skos:closeMatch/skos:Concept/skos:prefLabel">
          <xsl:value-of select="."/>
          <xsl:if test="position() != last()">
            <xsl:value-of select="$multisep"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:with-param>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- temporalCoverage -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="schema:temporalCoverage"/>
    </xsl:call-template>
    <xsl:value-of select="$sep"/>
    
    <!-- coverage -->
    <xsl:call-template name="escape-csv">
      <xsl:with-param name="value" select="dc:coverage"/>
    </xsl:call-template>
    
    <xsl:value-of select="$nl"/>
  </xsl:template>

  <!-- Escape CSV field: quote if contains comma, quote, or newline -->
  <xsl:template name="escape-csv">
    <xsl:param name="value"/>
    <xsl:variable name="escaped">
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$value"/>
        <xsl:with-param name="replace" select="'&quot;'"/>
        <xsl:with-param name="with" select="'&quot;&quot;'"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:choose>
      <xsl:when test="contains($value, ',') or contains($value, '&quot;') or contains($value, '&#10;') or contains($value, '&#13;')">
        <xsl:text>"</xsl:text>
        <xsl:value-of select="$escaped"/>
        <xsl:text>"</xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$escaped"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- String replace helper -->
  <xsl:template name="replace-string">
    <xsl:param name="text"/>
    <xsl:param name="replace"/>
    <xsl:param name="with"/>
    <xsl:choose>
      <xsl:when test="contains($text, $replace)">
        <xsl:value-of select="substring-before($text, $replace)"/>
        <xsl:value-of select="$with"/>
        <xsl:call-template name="replace-string">
          <xsl:with-param name="text" select="substring-after($text, $replace)"/>
          <xsl:with-param name="replace" select="$replace"/>
          <xsl:with-param name="with" select="$with"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$text"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
