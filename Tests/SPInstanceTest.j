/*
 * SPInstanceTest.j
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

@implementation SPInstanceTest : OJTestCase

- (void)testInstanceWithJSON
{
    var result = {
        "uri": {
            "type": "uri",
            "value": "http://example.org/Alice/"
        }
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var alice = [SPInstance instanceWithJSON:result];

    [self assert:result.uri.value equals:[alice URI]];
}

- (void)testInstanceWithJSONAndClass
{
    var result = {
        "uri": {
            "type": "uri",
            "value": "http://example.org/Alice/"
        }
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var alice = [SPInstance instanceWithJSON:result class:people];

    [self assert:result.uri.value equals:[alice URI]];
}

- (void)testInstanceWithJSONAndEndPoint
{
    var result = {
        "uri": {
            "type": "uri",
            "value": "http://example.org/Alice/"
        }
    };

    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [endPoint classForName:@"ex:Person"];
    var alice = [SPInstance instanceWithJSON:result endPoint:endPoint];

    [self assert:[alice endPoint] equals:endPoint];
}

- (void)testParseData
{
    var result = {
	"head": { "vars": [ "predicate", "object" ] },
	"results": {
	    "bindings": [
                {
                    "predicate": {
                        "type": "uri",
                        "value": "http://www.w3.org/2000/01/rdf-schema#label"
                     },
                    "object": {
                        "type": "literal",
                        "xml:lang": "en",
                        "value": "Karl Marx"
                    }
                }
             ]
	}
    };

    var store = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var people = [store classForName:@"ex:Person"];
    var instance = [[SPInstance alloc] initWithURI:@"http://example.org/kmarx" forClass:people];
    [instance parseData:result tag:0];

    [self assert:[SPPlainLiteral class]
	  equals:[[instance property:@"http://www.w3.org/2000/01/rdf-schema#label"] class]];
    [self assert:@"Karl Marx"
	  equals:[[instance property:@"http://www.w3.org/2000/01/rdf-schema#label"] description]];
    [self assert:@"Karl Marx"
	  equals:[[instance property:@"rdfs:label"] description]];
}

- (void)testParseDataCardinalityTwo
{
    // Zero Wing ;-)
    var result = {
	"head": { "vars": [ "predicate", "object" ] },
	"results": {
	    "bindings": [
                {
                    "predicate": {
                        "type": "uri",
                        "value": "http://www.w3.org/2000/01/rdf-schema#comment"
                     },
                    "object": {
                        "type": "literal",
                        "xml:lang": "en",
                        "value": "Mechanic: Somebody set up us the bomb."
                    }
                },
                {
                    "predicate": {
                        "type": "uri",
                        "value": "http://www.w3.org/2000/01/rdf-schema#comment"
                     },
                    "object": {
                        "type": "literal",
                        "xml:lang": "jp",
                        "value": "機関士：何者かによって、爆発物が仕掛けられたようです。"
                    }
                },
             ]
	}
    };

    var instance = [[SPInstance alloc] initWithURI:@"http://example.org/toaplan"];
    [instance parseData:result tag:0];

    [self assertTrue:[[instance property:@"rdfs:comment"] isKindOfClass:[CPArray class]]];
    [self assert:@"Mechanic: Somebody set up us the bomb."
	  equals:[[[instance property:@"rdfs:comment"] objectAtIndex:0] description]];
    [self assert:@"機関士：何者かによって、爆発物が仕掛けられたようです。"
	  equals:[[[instance property:@"rdfs:comment"] objectAtIndex:1] description]];
}

- (void)testParseDataMissingVars
{
    var result = {
	"head": { "vars": [ "foo" ] },
	"results": {
	    "bindings": [
                {
                    "predicate": {
                        "type": "uri",
                        "value": "http://www.w3.org/2000/01/rdf-schema#comment"
                     },
                    "object": {
                        "type": "literal",
                        "xml:lang": "jp",
                        "value": "機関士：何者かによって、爆発物が仕掛けられたようです。"
                    }
                }
	     ]
	}
    };

    var instance = [[SPInstance alloc] initWithURI:@"http://example.org/foo"];
    [self assertThrows:function(){ [instance parseData:result tag:0]; }];
}

- (void)testSetObjectForProperty
{
    var instance = [[SPInstance alloc] initWithURI:@"http://example.org/foo"];
    [self assert:nil equals:[instance property:@"foaf:name"]];

    [instance setObject:[[SPPlainLiteral alloc] initWithValue:@"foo"] forProperty:@"foaf:name"];

    [self assertTrue:[[instance property:@"foaf:name"] isKindOfClass:[SPPlainLiteral class]]];

    [instance setObject:[[SPPlainLiteral alloc] initWithValue:@"foo"] forProperty:@"foaf:name"];
    [self assertTrue:[[instance property:@"foaf:name"] isKindOfClass:[CPArray class]]];
}

- (void)testBuildInverseQuery
{
    var expectedSPARQL = "" +
	"SELECT\n" +
	"?uri\n" +
        "WHERE\n" +
	"{\n" +
	"?uri <http://dbpedia.org/ontology/disambiguates> <http://dbpedia.org/resource/Lance_Armstrong> .\n" +
        "}";

    var theClass = [[SPClass alloc] initWithClassName:@"dbo:Athlete"],
        instance = [[SPInstance alloc] initWithURI:@"http://dbpedia.org/resource/Lance_Armstrong"
                                          forClass:theClass],
        inverseProperty = @"dbo:disambiguates";

    var builder = [SPQueryBuilder select:@"?uri"];
    [builder where:SPTriple(@"?uri", inverseProperty, [instance URI])];

    var resultCollection = [instance inverse:inverseProperty];
    [self assert:expectedSPARQL equals:[resultCollection._query description]];

    [[resultCollection all] addObject:@"Test"];

    // Check the previous collecton was updated (cached).
    [self assert:1 equals:[[instance inverse:inverseProperty] count]];
}

@end
