<?xml version="1.0" encoding="UTF-8"?>
<!--
  FAST MARC XML to SKOS/RDF Transformation
  
  Converts OCLC FAST authority records from MARC XML format to SKOS/RDF.
  
  Input:  FAST MARC XML authority file (e.g., FASTTopical.marcxml)
  Output: SKOS/RDF XML file
  
  Parameters:
    facetType - The FAST facet type (Topical, Personal, Geographic, etc.)
                Passed from Makefile based on input filename.
  
  References:
    - ATHENA D4.2 Guidelines for mapping into SKOS
    - FAST documentation: https://www.oclc.org/research/areas/data-science/fast.html
    
  MARC field mapping:
    001       -> dc:identifier, skos:notation
    024$a     -> rdf:about URI (when $2='uri')
    1XX       -> skos:prefLabel
    4XX       -> skos:altLabel  
    5XX       -> skos:broader/narrower/related (based on $w)
    7XX       -> skos:closeMatch (LCSH cross-reference)
    043$a     -> dc:coverage (geographic area code)
    046$s/$t  -> schema:temporalCoverage
    680       -> skos:scopeNote
    688       -> skos:editorialNote
-->
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:mx="http://www.loc.gov/MARC21/slim"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
    xmlns:schema="http://schema.org/"
    xmlns:fast="http://id.worldcat.org/fast/ontology/"
    exclude-result-prefixes="mx">
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8"/>
    
    <xsl:variable name="fastBase">http://id.worldcat.org/fast/</xsl:variable>
    
    <!-- Parameter to inject facet type from Makefile -->
    <xsl:param name="facetType" select="''"/>
    
    <xsl:template match="/">
        <rdf:RDF>
            <!-- Define the FAST concept scheme -->
            <skos:ConceptScheme rdf:about="http://id.worldcat.org/fast/">
                <skos:prefLabel xml:lang="en">Faceted Application of Subject Terminology</skos:prefLabel>
                <dc:title>FAST (Faceted Application of Subject Terminology)</dc:title>
                <dc:publisher>OCLC</dc:publisher>
            </skos:ConceptScheme>
            
            <xsl:apply-templates select="//mx:record"/>
        </rdf:RDF>
    </xsl:template>
    
    <xsl:template match="mx:record">
        <!-- Extract numeric ID from 001 (e.g., fst01352135 -> 1352135) -->
        <xsl:variable name="rawId" select="normalize-space(mx:controlfield[@tag='001'])"/>
        <xsl:variable name="numericId" select="substring-after($rawId, 'fst')"/>
        
        <!-- Get URI from 024 if available, otherwise construct it -->
        <xsl:variable name="conceptURI">
            <xsl:choose>
                <xsl:when test="mx:datafield[@tag='024']/mx:subfield[@code='2']='uri'">
                    <xsl:value-of select="normalize-space(mx:datafield[@tag='024']/mx:subfield[@code='a'])"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="concat($fastBase, $numericId)"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        
        <skos:Concept rdf:about="{$conceptURI}">
            <!-- Identifier (fst code) -->
            <dc:identifier><xsl:value-of select="$rawId"/></dc:identifier>
            
            <!-- SKOS notation for language-independent matching (D4.2 §3.1) -->
            <skos:notation><xsl:value-of select="$rawId"/></skos:notation>
            
            <!-- Facet type if provided -->
            <xsl:if test="$facetType != ''">
                <fast:facet><xsl:value-of select="$facetType"/></fast:facet>
            </xsl:if>
            
            <!-- Link to scheme -->
            <skos:inScheme rdf:resource="http://id.worldcat.org/fast/"/>
            
            <!-- Preferred labels from 1XX fields -->
            <xsl:apply-templates select="mx:datafield[@tag='100' or @tag='110' or @tag='111' or @tag='130' or @tag='147' or @tag='148' or @tag='150' or @tag='151' or @tag='155' or @tag='180' or @tag='181' or @tag='182' or @tag='185']" mode="prefLabel"/>
            
            <!-- Alternate labels from 4XX fields -->
            <xsl:apply-templates select="mx:datafield[@tag='400' or @tag='410' or @tag='411' or @tag='430' or @tag='447' or @tag='448' or @tag='450' or @tag='451' or @tag='455' or @tag='480' or @tag='481' or @tag='482' or @tag='485']" mode="altLabel"/>
            
            <!-- Broader/narrower/related from 5XX fields -->
            <xsl:apply-templates select="mx:datafield[@tag='500' or @tag='510' or @tag='511' or @tag='530' or @tag='547' or @tag='548' or @tag='550' or @tag='551' or @tag='555' or @tag='580' or @tag='581' or @tag='582' or @tag='585']" mode="related"/>
            
            <!-- 7XX - Link to LC source heading -->
            <xsl:apply-templates select="mx:datafield[@tag='700' or @tag='710' or @tag='711' or @tag='730' or @tag='747' or @tag='748' or @tag='750' or @tag='751' or @tag='755']" mode="closeMatch"/>
            
            <!-- Date range from 046 -->
            <xsl:apply-templates select="mx:datafield[@tag='046']" mode="temporal"/>
            
            <!-- Geographic code from 043 -->
            <xsl:apply-templates select="mx:datafield[@tag='043']" mode="geographic"/>
            
            <!-- Scope notes from 680 -->
            <xsl:apply-templates select="mx:datafield[@tag='680']" mode="scopeNote"/>
            
            <!-- Editorial notes from 688 -->
            <xsl:apply-templates select="mx:datafield[@tag='688']" mode="editorialNote"/>
        </skos:Concept>
    </xsl:template>
    
    <!-- Preferred Label -->
    <xsl:template match="mx:datafield" mode="prefLabel">
        <skos:prefLabel xml:lang="en">
            <xsl:call-template name="buildLabel"/>
        </skos:prefLabel>
    </xsl:template>
    
    <!-- Alternate Label -->
    <xsl:template match="mx:datafield" mode="altLabel">
        <skos:altLabel xml:lang="en">
            <xsl:call-template name="buildLabel"/>
        </skos:altLabel>
    </xsl:template>
    
    <!-- Related/Broader/Narrower -->
    <xsl:template match="mx:datafield" mode="related">
        <xsl:variable name="w" select="mx:subfield[@code='w']"/>
        <xsl:variable name="targetId" select="normalize-space(mx:subfield[@code='0'])"/>
        
        <xsl:if test="$targetId != ''">
            <xsl:variable name="targetURI">
                <xsl:choose>
                    <xsl:when test="starts-with($targetId, 'fst')">
                        <xsl:value-of select="concat($fastBase, substring-after($targetId, 'fst'))"/>
                    </xsl:when>
                    <xsl:when test="starts-with($targetId, 'http')">
                        <xsl:value-of select="$targetId"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="concat($fastBase, $targetId)"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            
            <xsl:choose>
                <xsl:when test="contains($w, 'g')">
                    <skos:broader rdf:resource="{$targetURI}"/>
                </xsl:when>
                <xsl:when test="contains($w, 'h')">
                    <skos:narrower rdf:resource="{$targetURI}"/>
                </xsl:when>
                <xsl:otherwise>
                    <skos:related rdf:resource="{$targetURI}"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>
    
    <!-- Close match to LCSH from 7XX -->
    <xsl:template match="mx:datafield" mode="closeMatch">
        <xsl:variable name="lccn" select="normalize-space(mx:subfield[@code='0'])"/>
        <xsl:if test="$lccn != ''">
            <xsl:variable name="lcHeading">
                <xsl:call-template name="buildLabel"/>
            </xsl:variable>
            <skos:closeMatch>
                <skos:Concept>
                    <skos:prefLabel xml:lang="en"><xsl:value-of select="$lcHeading"/></skos:prefLabel>
                    <skos:notation><xsl:value-of select="$lccn"/></skos:notation>
                    <skos:inScheme rdf:resource="http://id.loc.gov/authorities/subjects"/>
                </skos:Concept>
            </skos:closeMatch>
        </xsl:if>
    </xsl:template>
    
    <!-- Temporal coverage from 046 -->
    <xsl:template match="mx:datafield[@tag='046']" mode="temporal">
        <xsl:variable name="startDate" select="normalize-space(mx:subfield[@code='s'])"/>
        <xsl:variable name="endDate" select="normalize-space(mx:subfield[@code='t'])"/>
        <xsl:if test="$startDate != ''">
            <schema:temporalCoverage>
                <xsl:value-of select="$startDate"/>
                <xsl:if test="$endDate != ''">
                    <xsl:text>/</xsl:text>
                    <xsl:value-of select="$endDate"/>
                </xsl:if>
            </schema:temporalCoverage>
        </xsl:if>
    </xsl:template>
    
    <!-- Geographic area code from 043 -->
    <xsl:template match="mx:datafield[@tag='043']" mode="geographic">
        <xsl:for-each select="mx:subfield[@code='a']">
            <dc:coverage><xsl:value-of select="normalize-space(.)"/></dc:coverage>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Scope note from 680 -->
    <xsl:template match="mx:datafield[@tag='680']" mode="scopeNote">
        <skos:scopeNote xml:lang="en">
            <xsl:for-each select="mx:subfield[@code='i' or @code='a']">
                <xsl:value-of select="normalize-space(.)"/>
                <xsl:if test="position() != last()">
                    <xsl:text> </xsl:text>
                </xsl:if>
            </xsl:for-each>
        </skos:scopeNote>
    </xsl:template>
    
    <!-- Editorial note from 688 -->
    <xsl:template match="mx:datafield[@tag='688']" mode="editorialNote">
        <skos:editorialNote xml:lang="en">
            <xsl:value-of select="normalize-space(mx:subfield[@code='a'])"/>
        </skos:editorialNote>
    </xsl:template>
    
    <!-- Build label from subfields - preserves internal MARC punctuation, strips trailing -->
    <xsl:template name="buildLabel">
        <xsl:variable name="subfields" select="mx:subfield[not(@code='w' or @code='0' or @code='2' or @code='4' or @code='5' or @code='6' or @code='8')]"/>
        <xsl:for-each select="$subfields">
            <xsl:variable name="rawValue" select="normalize-space(.)"/>
            <!-- Strip trailing punctuation only from the LAST subfield -->
            <xsl:variable name="value">
                <xsl:choose>
                    <xsl:when test="position() = last()">
                        <xsl:call-template name="stripTrailingPunct">
                            <xsl:with-param name="text" select="$rawValue"/>
                        </xsl:call-template>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="$rawValue"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="position() = 1">
                    <xsl:value-of select="$value"/>
                </xsl:when>
                <xsl:when test="@code='v' or @code='x' or @code='y' or @code='z'">
                    <!-- Subdivision separator without spaces, matching FAST display -->
                    <xsl:text>--</xsl:text>
                    <xsl:value-of select="$value"/>
                </xsl:when>
                <xsl:when test="@code='d'">
                    <!-- Dates: just add space, MARC punctuation on preceding subfield provides comma -->
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$value"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="$value"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Helper: strip trailing punctuation, but preserve abbreviations -->
    <xsl:template name="stripTrailingPunct">
        <xsl:param name="text"/>
        <xsl:variable name="lastChar" select="substring($text, string-length($text))"/>
        <xsl:variable name="lastTwo" select="substring($text, string-length($text) - 1)"/>
        <xsl:variable name="lastThree" select="substring($text, string-length($text) - 2)"/>
        <xsl:variable name="lastFour" select="substring($text, string-length($text) - 3)"/>
        <xsl:variable name="lastFive" select="substring($text, string-length($text) - 4)"/>
        <xsl:choose>
            <!-- Keep trailing comma or semicolon only (always strip these) -->
            <xsl:when test="$lastChar = ',' or $lastChar = ';'">
                <xsl:value-of select="substring($text, 1, string-length($text) - 1)"/>
            </xsl:when>
            <!-- Preserve single-letter initials (A. B. C. etc.) -->
            <xsl:when test="$lastChar = '.' and string-length($text) >= 2 and contains('ABCDEFGHIJKLMNOPQRSTUVWXYZ', substring($text, string-length($text) - 1, 1)) and (string-length($text) = 2 or substring($text, string-length($text) - 2, 1) = ' ')">
                <xsl:value-of select="$text"/>
            </xsl:when>
            <!-- Preserve common abbreviations -->
            <xsl:when test="$lastFour = 'etc.' or $lastThree = 'Jr.' or $lastThree = 'Sr.' or $lastFive = 'Dept.' or $lastFour = 'Inc.' or $lastFour = 'Ltd.' or $lastThree = 'Co.' or $lastFive = 'Corp.' or $lastFive = 'Bros.' or $lastFive = 'Assn.' or $lastThree = 'Dr.' or $lastThree = 'Mr.' or $lastFour = 'Mrs.' or $lastThree = 'Ms.' or $lastThree = 'St.' or $lastThree = 'Mt.' or $lastThree = 'Ft.' or $lastThree = 'ca.' or $lastThree = 'fl.' or $lastThree = 'vs.'">
                <xsl:value-of select="$text"/>
            </xsl:when>
            <!-- Strip other trailing periods -->
            <xsl:when test="$lastChar = '.'">
                <xsl:value-of select="substring($text, 1, string-length($text) - 1)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$text"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
</xsl:stylesheet>
