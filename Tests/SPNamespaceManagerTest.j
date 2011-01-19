/*
 * SPNamespaceManagerTest.j
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

@implementation SPNamespaceManagerTest : OJTestCase

- (void)testSharedManager
{
    [self assertTrue:[SPNamespaceManager sharedManager] != nil];
}

- (void)testAddNamespaceForPrefix
{
    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"ns"];
    [self assert:@"http://example.org/ns#"
	  equals:[[SPNamespaceManager sharedManager] namespaceForPrefix: @"ns"]];
}

- (void)testExpandQualifiedName
{
    var labelNamespace = @"http://www.w3.org/2000/01/rdf-schema#label";
    [self assert:labelNamespace
	  equals:[[SPNamespaceManager sharedManager] expandQualifiedName:@"rdfs:label"]];
    [self assert:labelNamespace
	  equals:[[SPNamespaceManager sharedManager] expandQualifiedName:labelNamespace]];

    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"ns"];
    [self assert:@"http://example.org/ns#foo"
	  equals:[[SPNamespaceManager sharedManager] expandQualifiedName:@"ns:foo"]];
}

- (void)testSPSplitQualifiedName
{
    [self assertTrue:SPSplitQualifiedName(@"foaf:name")];
    [self assertTrue:SPSplitQualifiedName(@"owl:name")];
    [self assertTrue:SPSplitQualifiedName(@"db-ont:name")];
    [self assertFalse:SPSplitQualifiedName(@"name")];
    [self assertFalse:SPSplitQualifiedName(@"<http://dbpedia.org/ontology/Automobile>")];

    [self assert:@"foaf" equals:SPSplitQualifiedName(@"foaf:name").prefix];
    [self assert:@"name" equals:SPSplitQualifiedName(@"foaf:name").localName];
}

@end
