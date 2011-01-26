/*
 * SPCollectionResultTest.j
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

@implementation SPCollectionResultTest : OJTestCase

- (void)testBuildCountQuery
{
    var expectedSPARQL = "" +
	"PREFIX dbo: <http://dbpedia.org/ontology/>\n" +
	"SELECT\n" +
	"(COUNT(?g) as ?count)\n" +
        "WHERE\n" +
	"{\n" +
	"GRAPH\n" +
        "?g\n" +
	"{\n" +
	"{\n" +
        "?uri a dbo:FormulaOneRacer .\n" +
	"}\n" +
	"}\n" +
        "}";

    var builder = [SPQueryBuilder select:@"*"];
    [builder where:SPTriple(@"?uri", @"a", @"dbo:FormulaOneRacer")];

    var resultCollection = [[SPCollectionResult alloc] initWithQuery:builder class:nil];
    [self assert:expectedSPARQL equals:[[resultCollection buildCountQuery] description]];
}

- (void)testParseData
{
    var result = {
	"head": { "vars": [ "uri" ] },
	"results": {
	    "bindings": [
	         { "uri": { "type": "uri", "value": "http://example.org/alice" } },
	         { "uri": { "type": "uri", "value": "http://example.org/bob" } }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:0];

    [self assert:result.results.bindings.length equals:[collectionResult count]];
    [self assert:@"http://example.org/alice"
	  equals:[[[collectionResult all] objectAtIndex:0] URI]];
    [self assert:@"http://example.org/bob"
	  equals:[[[collectionResult all] objectAtIndex:1] URI]];
}

- (void)testParseCountData
{
    var result = {
        "head": { "vars": [ "count" ] },
        "results": {
            "bindings": [{
		"count": {
		    "type": "typed-literal",
		    "value": "12345",
		    "datatype": "http://www.w3.org/2001/XMLSchema#integer"
		}
	    }]
        }
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:SPCollectionResultConnectionTagCount];

    [self assert:12345 equals:collectionResult._count];
}

- (void)testParseEmptyCountData
{
    var result = {
        "head": { "vars": [ "count" ] },
        "results": {
            "bindings": []
        }
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:SPCollectionResultConnectionTagCount];

    [self assert:nil equals:collectionResult._count];
}

- (void)testParseDataMissingVars
{
    var result = {
	"head": { "vars": [ "foo" ] },
	"results": {
	    "bindings": [
	         { "foo": { "type": "uri", "value": "http://example.org/foo" } }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [self assertThrows:function(){ [collectionResult parseData:result tag:0]; }];
}

- (void)testCount
{
   var result = {
	"head": { "vars": [ "uri" ] },
	"results": {
	    "bindings": [
	         { "uri": { "type": "uri", "value": "http://example.org/alice" } },
	         { "uri": { "type": "uri", "value": "http://example.org/bob" } }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:0];

    [self assert:result.results.bindings.length equals:[collectionResult count]];
}

- (void)testFirst
{
   var result = {
	"head": { "vars": [ "uri" ] },
	"results": {
	    "bindings": [
	         { "uri": { "type": "uri", "value": "http://example.org/alice" } },
	         { "uri": { "type": "uri", "value": "http://example.org/bob" } }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:0];

    [self assert:result.results.bindings[0].uri.value
	  equals:[[collectionResult first] URI]];
}

- (void)testAll
{
   var result = {
	"head": { "vars": [ "uri" ] },
	"results": {
	    "bindings": [
	         { "uri": { "type": "uri", "value": "http://example.org/alice" } },
	         { "uri": { "type": "uri", "value": "http://example.org/bob" } }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:0];

    [self assert:result.results.bindings.length
	  equals:[[collectionResult all] count]];
}

- (void)testEmptyCollection
{
   var result = {
	"head": { "vars": [ "uri" ] },
	"results": {
	    "bindings": [
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];
    [collectionResult parseData:result tag:0];

    [self assert:0 equals:[[collectionResult all] count]];
}

- (void)testSetPreloadedPropertySingleTuple
{
    // tests parsing preloaded properties where each instance is
    // a single tuple (that is, no properties has a cardinality of > 1)
    var result = {
       "head": { "vars": [ "uri", "property1", "property2" ] },
	"results": {
	    "bindings": [
	         {
		     "uri": {
			 "type": "uri",
			 "value": "http://example.org/alice"
		     },
		     "property0": {
			 "type": "literal",
			 "xml:lang": "en",
			 "value": "England"
		     },
		     "property1": {
			 "type": "uri",
			 "value": "http://dbpedia.org/resource/England"
		     },
		 },
	         {
		     "uri": {
			 "type": "uri",
			 "value": "http://example.org/bob"
		     },
		     "property0": {
			 "type": "literal",
			 "xml:lang": "en",
			 "value": "France"
		     },
		     "property1": {
			 "type": "uri",
			 "value": "http://dbpedia.org/resource/France"
		     },
		 }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var collectionResult = [people all];

    [collectionResult setPreloadedProperties:@"rdfs:label", @"dbo:birthPlace"];

    [collectionResult parseData:result tag:0];

    var alice = [[collectionResult all] objectAtIndex:0],
	bob = [[collectionResult all] objectAtIndex:1];

    [self assert:[alice URI] equals:@"http://example.org/alice"];
    [self assert:[bob URI] equals:@"http://example.org/bob"];

    [self assert:@"England" equals:[[alice property:"rdfs:label"] value]];
    [self assert:[[alice property:"dbo:birthPlace"] value]
	  equals:@"http://dbpedia.org/resource/England"];
    [self assertTrue:[[alice property:"dbo:birthPlace"] isKindOfClass:[SPLiteralURI class]]];

    [self assert:@"France" equals:[[bob property:"rdfs:label"] value]];
    [self assert:[[bob property:"dbo:birthPlace"] value]
	  equals:@"http://dbpedia.org/resource/France"];
    [self assertTrue:[[bob property:"dbo:birthPlace"] isKindOfClass:[SPLiteralURI class]]];
}

- (void)testSetPreloadedPropertyMultipleTuple
{
    // tests parsing preloaded properties where each a property has
    // a cardinality of > 1
    var result = {
       "head": { "vars": [ "uri", "property1", "property2" ] },
	"results": {
	    "bindings": [
	         {
		     "uri": {
			 "type": "uri",
			 "value": "http://example.org/alice"
		     },
		     "property0": {
			 "type": "literal",
			 "xml:lang": "en",
			 "value": "England"
		     },
		     "property1": {
			 "type": "uri",
			 "value": "http://dbpedia.org/resource/England"
		     },
		 },
	         {
		     "uri": {
			 "type": "uri",
			 "value": "http://example.org/bob"
		     },
		     "property0": {
			 "type": "literal",
			 "xml:lang": "en",
			 "value": "France"
		     },
		     "property1": {
			 "type": "uri",
			 "value": "http://dbpedia.org/resource/France"
		     }
		 },
	         {
		     "uri": {
			 "type": "uri",
			 "value": "http://example.org/bob"
		     },
		     "property0": {
			 "type": "literal",
			 "xml:lang": "fr",
			 "value": "Francis"
		     },
		     "property1": {
			 "type": "uri",
			 "value": "http://dbpedia.org/resource/France"
		     }
		 }
             ]
	}
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"foaf:Person"];
    var collectionResult = [people all];

    [collectionResult setPreloadedProperties:@"rdfs:label", @"dbo:birthPlace"];

    [collectionResult parseData:result tag:0];

    var bob = [[collectionResult all] objectAtIndex:1];

    [self assertTrue:[[bob property:"rdfs:label"] isKindOfClass:[CPArray class]]];
    [self assert:[[bob property:"rdfs:label"] count] equals:2];
}

- (void)testBuildPreloadedQuery
{
    var expectedSPARQL = "" +
        "PREFIX foaf: <http://xmlns.com/foaf/0.1/>\n" +
	"SELECT\n" +
	"DISTINCT\n" +
	"?uri ?property0 ?property1\n" +
	"WHERE\n" +
	"{\n" +
	"?uri a foaf:Person .\n" +
	"OPTIONAL\n" +
	"{\n" +
	"?uri foaf:name ?property0 .\n" +
	"}\n" +
	"OPTIONAL\n" +
	"{\n" +
	"?uri foaf:mbox ?property1 .\n" +
	"}\n" +
	"}\n" +
	"ORDER BY DESC(?uri)";


    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"foaf:Person"];
    var collectionResult = [people all];

    [collectionResult setPreloadedProperties:@"foaf:name", @"foaf:mbox"];
    [collectionResult buildPreloadedPropertiesQuery];

    [self assert:expectedSPARQL equals:[collectionResult._query description]];
}

@end
