/*
 * SPQueryBuilderTest.j
 * Sparkles - SPARQL for Cappuccino.
 *
 * Created by Martin Galpin.
 * Copyright 2010, 66laps Limited.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import "../Sparkles.j"

@implementation SPQueryBuilderTest : OJTestCase

- (void)setUp
{
    [[SPNamespaceManager sharedManager] removeAllObjects];
}

- (void)testSelect
{
    var expectedSPARQL = "" +
	"SELECT\n" +
	"*\n" +
        "WHERE\n" +
	"{\n" +
        "?s ?p ?o .\n" +
        "}";

    var builder = [SPQueryBuilder select:@"*"];
    [builder where:SPTriple(@"?s", @"?p", @"?o")];
    [self assert:expectedSPARQL equals:[builder description]];
}

- (void)testSelectWhere
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?nameX ?nameY ?nickY\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:knows ?y .\n" +
        "?x foaf:name ?nameX .\n" +
        "?y foaf:name ?nameY .\n" +
        "OPTIONAL\n" +
	"{\n" +
	"?y foaf:nick ?nickY .\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?nameX", @"?nameY", @"?nickY"];
    [builder where:SPTriple(@"?x", @"foaf:knows", @"?y"),
		   SPTriple(@"?x", @"foaf:name", @"?nameX"),
	           SPTriple(@"?y", @"foaf:name", @"?nameY"),
	           SPOptional(SPTriple(@"?y", @"foaf:nick", @"?nickY"))];
    [self assert:expectedSPARQL equals:[builder description]];
}


// SPARQL queries from: http://www.w3.org/TR/rdf-sparql-query/#solutionModifiers
- (void)testOrderBy
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}\n" +
	"ORDER BY ?name";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [builder orderBy:@"?name"]
    [self assert:expectedSPARQL equals:[builder description]];

    expectedSPARQL = "" +
	"PREFIX : <http://example.org/ns#>\n" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
	"?x :empId ?emp .\n" +
        "}\n" +
	"ORDER BY DESC(?name)";

    builder = [SPQueryBuilder select:@"?name"];
    [builder setEmptyNamespace:@"http://example.org/ns#"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name"),
	           SPTriple(@"?x", @":empId", @"?emp")];
    [builder orderBy:@"DESC(?name)"]
    [self assert:expectedSPARQL equals:[builder description]];

    expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
	"?x :empId ?emp .\n" +
        "}\n" +
	"ORDER BY ?name DESC(?name)";

    builder = [SPQueryBuilder select:@"?name"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name"),
	           SPTriple(@"?x", @":empId", @"?emp")];
    [builder orderBy:@"?name", @"DESC(?name)"]
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#modDistinct
- (void)testSelectDistinct
{
    var expectedSPARQL = "" +
	"PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"DISTINCT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder setDistinct:YES];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#modReduced
- (void)testSelectReduced
{
    var expectedSPARQL = "" +
	"PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"REDUCED\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder setReduced:YES];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#modOffset
- (void)testSelectOffset
{
    var expectedSPARQL = "" +
	"PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}\n" +
	"LIMIT 5\n" +
	"OFFSET 10";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [builder setOffset:10];
    [builder setLimit:5];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#modLimit
- (void)testSelectLimit
{
    var expectedSPARQL = "" +
	"PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"?name\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}\n" +
	"LIMIT 20";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [builder setLimit:20];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#basicpatterns
- (void)testSelectFilters
{
    var expectedSPARQL = "" +
        "PREFIX dc: <http://purl.org/dc/terms/>\n" +
        "SELECT\n" +
	"?title\n" +
        "WHERE\n" +
	"{\n" +
	"?x dc:title ?title .\n" +
	'FILTER regex(?title, "web", "i")\n' +
        "}";

    var builder = [SPQueryBuilder select:@"?title"];
    [builder where:SPTriple(@"?x", @"dc:title", @"?title"),
	           SPFilter(@"regex(?title, \"web\", \"i\")")];
    [self assert:expectedSPARQL equals:[builder description]];

    expectedSPARQL = "" +
        "PREFIX dc: <http://purl.org/dc/terms/>\n" +
	"PREFIX ns: <http://example.org/ns#>\n" +
        "SELECT\n" +
	"?title ?price\n" +
        "WHERE\n" +
	"{\n" +
	"?x ns:price ?price .\n" +
	"FILTER (?price < 30.5)\n" +
	"?x dc:title ?title .\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?title", @"?price"];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"ns"];
    [builder where:SPTriple(@"?x", @"ns:price", @"?price"),
	           SPFilter(@"(?price < 30.5)"),
	           SPTriple(@"?x", @"dc:title", @"?title")];
    [self assert:expectedSPARQL equals:[builder description]];
}

- (void)testMatchNamespaceOptionalGroup
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?nameX ?nameY ?nickY\n" +
        "WHERE\n" +
	"{\n" +
        "OPTIONAL\n" +
	"{\n" +
	"?y foaf:nick ?nickY .\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?nameX", @"?nameY", @"?nickY"];
    [builder where:SPOptional(SPTriple(@"?y", @"foaf:nick", @"?nickY"))];
    [self assert:expectedSPARQL equals:[builder description]];
}

- (void)testAddNamespaceForPrefix
{
    var expected = "" +
	"PREFIX ns: <http://example.org/ns#>\n" +
	"SELECT\n" +
	"?foo";

    var builder = [SPQueryBuilder select:@"?foo"];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"ns"];

    [self assert:expected equals:[builder description]];
}

- (void)testUnusedNamespacePrefix
{
    var expected = "" +
	"PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"?foo\n" +
	"WHERE\n"+
	"{\n" +
	"?foo foaf:name \"Steve\" .\n" +
	"}";

    var builder = [SPQueryBuilder select:@"?foo"];
    [[SPNamespaceManager alloc] addNamespace:@"http://example.org/ns#" forPrefix:@"ns"];
    [[SPNamespaceManager alloc] addNamespace:@"http://xmlns.com/foaf/0.1/" forPrefix:@"foaf"];
    [builder where:SPTriple(@"?foo", "foaf:name", @"\"Steve\"")];

    [self assert:expected equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#MultipleOptionals
- (void)testSelectMultipleOptional
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
        "SELECT\n" +
	"?name ?mbox ?name\n" +
        "WHERE\n" +
	"{\n" +
	"?x foaf:name ?name .\n" +
	"OPTIONAL\n" +
	"{\n" +
	"?x foaf:mbox ?mbox .\n" +
	"}\n" +
	"OPTIONAL\n" +
	"{\n" +
	"?x foaf:homepage ?hpage .\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?name", @"?mbox", @"?name"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name"),
	                    SPOptional(SPTriple(@"?x", @"foaf:mbox", @"?mbox")),
                            SPOptional(SPTriple(@"?x", @"foaf:homepage", @"?hpage"))];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL queries from: http://www.w3.org/TR/rdf-sparql-query/#alternatives
- (void)testMatchingAlternatives
{
    var expectedSPARQL = "" +
	"PREFIX dc11: <http://purl.org/dc/elements/1.1/>\n" +
        "PREFIX dc10: <http://purl.org/dc/elements/1.0/>\n" +
        "SELECT\n" +
	"?title\n" +
        "WHERE\n" +
	"{\n" +
	"{\n" +
	"?book dc10:title ?title .\n" +
	"}\n" +
	"UNION\n" +
	"{\n" +
	"?book dc11:title ?title .\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder select:@"?title"];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://purl.org/dc/elements/1.0/" forPrefix:@"dc10"];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://purl.org/dc/elements/1.1/" forPrefix:@"dc11"];
    [builder where:SPUnion(SPGraph(SPTriple(@"?book", @"dc10:title", @"?title")),
			   SPGraph(SPTriple(@"?book", @"dc11:title", @"?title")))];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL queries from: http://www.w3.org/TR/rdf-sparql-query/#construct
- (void)testConstruct
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>\n" +
	"CONSTRUCT\n" +
	"{\n" +
	"<http://example.org/person#Alice> vcard:FN ?name .\n" +
	"}\n" +
        "WHERE\n" +
	"{\n" +
        "?x foaf:name ?name .\n" +
        "}";

    var builder = [SPQueryBuilder construct:SPTriple(@"<http://example.org/person#Alice>", @"vcard:FN", @"?name")];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#tempatesWithBNodes
- (void)testConstructTemplateWithBlankNodes
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"PREFIX vcard: <http://www.w3.org/2006/vcard/ns#>\n" +
	"CONSTRUCT\n" +
	"{\n" +
	"?x vcard:N _:v .\n" +
	"_:v vcard:givenName ?gname .\n" +
	"_:v vcard:familyName ?fname .\n" +
	"}\n" +
        "WHERE\n" +
	"{\n" +
	"{\n" +
        "?x foaf:firstname ?gname .\n" +
	"}\n" +
	"UNION\n" +
	"{\n" +
        "?x foaf:givenName ?gname .\n" +
	"}\n" +
	"{\n" +
        "?x foaf:surname ?fname .\n" +
	"}\n" +
	"UNION\n" +
	"{\n" +
        "?x foaf:family_name ?fname .\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder construct:SPTriple(@"?x", @"vcard:N", @"_:v"),
				            SPTriple(@"_:v", @"vcard:givenName", @"?gname"),
			                    SPTriple(@"_:v", @"vcard:familyName", @"?fname")];
    [builder where:SPUnion(SPGraph(SPTriple(@"?x", @"foaf:firstname", @"?gname")),
			   SPGraph(SPTriple(@"?x", @"foaf:givenName", @"?gname"))),
		   SPUnion(SPGraph(SPTriple(@"?x", @"foaf:surname", @"?fname")),
			   SPGraph(SPTriple(@"?x", @"foaf:family_name", @"?fname")))];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#accessingRdfGraphs
- (void)testConstructAccessGraphs
{
    var expectedSPARQL = "" +
	"PREFIX app: <http://example.org/ns#>\n" +
        "PREFIX dc: <http://purl.org/dc/terms/>\n" +
	"CONSTRUCT\n" +
	"{\n" +
	"?s ?p ?o .\n" +
	"}\n" +
        "WHERE\n" +
	"{\n" +
	"GRAPH\n" +
	"?g\n" +
	"{\n" +
	"?s ?p ?o .\n" +
	"}\n" +
	"{\n" +
        "?g dc:publisher <http://www.w3c.org/> .\n" +
	"}\n" +
	"{\n" +
        "?g dc:date ?date .\n" +
	"}\n" +
	'FILTER (app:customDate(?date) > "2005-02-28T00:00:00Z"^^xsd:dateTime)\n' +
        "}";

    var builder = [SPQueryBuilder construct:SPTriple(@"?s", @"?p", @"?o")];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"app"];
    [builder where:SPNamed(@"?g", SPTriple(@"?s", @"?p", @"?o")),
	           SPGraph(SPTriple(@"?g", @"dc:publisher", @"<http://www.w3c.org/>")),
	           SPGraph(SPTriple(@"?g", @"dc:date", @"?date")),
	           SPFilter(@"(app:customDate(?date) > \"2005-02-28T00:00:00Z\"^^xsd:dateTime)")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#SolModandCONSTRUCT
- (void)testConstructSolutionModifiers
{
    var expectedSPARQL = "" +
        "PREFIX site: <http://example.org/stats#>\n" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"CONSTRUCT\n" +
	"{\n" +
	"[] foaf:name ?name .\n" +
	"}\n" +
        "WHERE\n" +
	"{\n" +
	"[] foaf:name ?name .\n" +
	"[] site:hits ?hits .\n" +
	"}\n" +
	'ORDER BY desc(?hits)\n' +
	"LIMIT 2"

    var builder = [SPQueryBuilder construct:SPTriple(@"[]", @"foaf:name", @"?name")];
    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/stats#" forPrefix:@"site"];
    [builder where:SPTriple(@"[]", @"foaf:name", @"?name"),
	           SPTriple(@"[]", @"site:hits", @"?hits")];
    [builder orderBy:@"desc(?hits)"];
    [builder setLimit:2];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#ask
- (void)testAsk
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"ASK\n" +
	"{\n" +
	"?x foaf:name \"Alice\" .\n" +
	"?x foaf:mbox <mailto:alice@work.example> .\n" +
	"}";

    var builder = [SPQueryBuilder ask:SPTriple(@"?x", @"foaf:name", @"\"Alice\""),
				      SPTriple(@"?x", @"foaf:mbox", @"<mailto:alice@work.example>")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#describe
- (void)testDescribe
{
    var expectedSPARQL = "" +
	"DESCRIBE\n" +
	"<http://www.example.org>";

    var builder = [SPQueryBuilder describe:@"<http://www.example.org>"];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#identifyingResources
- (void)testDescribeIdentifyingResources
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"DESCRIBE\n" +
	"?x\n" +
	"WHERE\n" +
	"{\n" +
	"?x foaf:mbox <mailto:alice@org> .\n" +
	"}";

    var builder = [SPQueryBuilder describe:@"?x"];
    [builder where:SPTriple(@"?x", @"foaf:mbox", @"<mailto:alice@org>")];
    [self assert:expectedSPARQL equals:[builder description]];
}

- (void)testDescribeSolutionModifiers
{
    var expectedSPARQL = "" +
	"DESCRIBE\n" +
	"<http://www.example.org>\n" +
	"LIMIT 20";

    var builder = [SPQueryBuilder describe:@"<http://www.example.org>"];
    [builder setLimit:20];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#namedGraphs
- (void)testFromNamed
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"?name\n" +
	"FROM\n" +
	"<http://example.org/foaf/aliceFoaf>\n" +
	"WHERE\n" +
	"{\n" +
	"?x foaf:name ?name .\n" +
	"}";

    var builder = [SPQueryBuilder select:@"?name"];
    [builder from:@"<http://example.org/foaf/aliceFoaf>"];
    [builder where:SPTriple(@"?x", @"foaf:name", @"?name")];
    [self assert:expectedSPARQL equals:[builder description]];
}

// SPARQL query from: http://www.w3.org/TR/rdf-sparql-query/#specDataset
- (void)testFromCombinedNamed
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"PREFIX dc: <http://purl.org/dc/terms/>\n" +
	"SELECT\n" +
	"?who ?g ?mbox\n" +
	"FROM\n" +
	"<http://example.org/dft.ttl>\n" +
	"FROM NAMED\n" +
	"<http://example.org/alice>\n" +
	"FROM NAMED\n" +
	"<http://example.org/bob>\n" +
	"WHERE\n" +
	"{\n" +
	"?g dc:publisher ?who .\n" +
	"GRAPH\n" +
	"?g\n" +
	"{\n" +
	"?x foaf:mbox ?mbox .\n" +
	"}\n" +
	"}";

    var builder = [SPQueryBuilder select:@"?who", @"?g", @"?mbox"];
    [builder from:@"<http://example.org/dft.ttl>"];
    [builder fromNamed:@"<http://example.org/alice>", @"<http://example.org/bob>"];
    [builder where:SPTriple(@"?g", @"dc:publisher", @"?who"),
	           SPNamed(@"?g", SPTriple(@"?x", @"foaf:mbox", @"?mbox"))];
    [self assert:expectedSPARQL equals:[builder description]];
}

- (void)testSPTriple
{
    var triple = SPTriple(@"?s", @"?p", @"?o");
    [self assert:@"?s ?p ?o ." equals:[triple description]];
}

- (void)testSPOptional
{
    var optional = SPOptional(SPTriple(@"?s", @"?o", @"?p"),
			      SPTriple(@"?s", @"foaf:name", @"?p")),
	expected = "OPTIONAL\n" +
	           "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name ?p .\n" +
	           "}";
    [self assert:expected equals:[optional description]];
}


- (void)testSPNamedGraph
{
    var namedGraph = SPNamed(@"?foo", SPTriple(@"?s", @"?o", @"?p"),
			   SPTriple(@"?s", @"foaf:name", @"?p")),
	expected = "GRAPH\n" +
	           "?foo\n" +
	           "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name ?p .\n" +
	           "}";
    [self assert:expected equals:[namedGraph description]];
}

- (void)testSPFilter
{
    var filter = SPFilter(@"regex(?x, '^foo')"),
	expected = "FILTER regex(?x, '^foo')";
    [self assert:expected equals:[filter description]];
}

- (void)testSPGraph
{
    var graph = SPGraph(SPTriple(@"?s", @"?o", @"?p"),
			SPTriple(@"?s", @"foaf:name", @"?p")),
	expected = "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name ?p .\n" +
	           "}";
    [self assert:expected equals:[graph description]];
}

- (void)testSPUnion
{
    var graph1 = SPGraph(SPTriple(@"?s", @"?o", @"?p"),
			 SPTriple(@"?s", @"foaf:name", @"?p")),
	graph2 = SPGraph(SPTriple(@"?s", @"?o", @"?p"),
			 SPTriple(@"?s", @"foaf:mbox", @"?mail")),
	graph3 = SPGraph(SPTriple(@"?s", @"?o", @"?p"),
			 SPTriple(@"?s", @"foaf:name", @"\"Alice\"")),
	union = SPUnion(graph1, graph2, graph3),
	expected = "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name ?p .\n" +
	           "}\n" +
	           "UNION\n" +
	           "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:mbox ?mail .\n" +
	           "}\n" +
	           "UNION\n" +
	           "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name \"Alice\" .\n" +
	           "}";
    [self assert:expected equals:[union description]];
}


- (void)testSPUnionSingle
{
    var graph1 = SPGraph(SPTriple(@"?s", @"?o", @"?p"),
			 SPTriple(@"?s", @"foaf:name", @"?p")),
	union = SPUnion(graph1),
	expected = "{\n" +
	           "?s ?o ?p .\n" +
	           "?s foaf:name ?p .\n" +
	           "}";
    [self assert:expected equals:[union description]];
}

- (void)testSPLanguage
{
    [self assert:@"?var FILTER(lang(?var) = 'en')" equals:SPLanguage("?var", "en")];
    [self assert:[SPTriple(@"?var", "rdfs:label", SPLanguage("?lbl", "en")) description]
	  equals:@"?var rdfs:label ?lbl FILTER(lang(?lbl) = 'en') ."];
}

@end
