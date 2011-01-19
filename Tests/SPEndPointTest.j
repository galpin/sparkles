/*
 * SPEndPointTest.j
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

@implementation SPEndPointTest : OJTestCase

- (void)testInitWithEndPoint
{
    var endPoint = @"http://dbpedia.org/sparql";
    var store = [SPEndPoint endPointWithString:endPoint];
    [self assert:endPoint equals:[[store URL] description]];
}

- (void)testClassForNameNamespace
{
    var defaultNamespace = @"http://xmlns.com/foaf/0.1/";
    var endPoint = @"http://dbpedia.org/sparql";
    var store = [[SPEndPoint alloc] initWithURL:[CPURL URLWithString:endPoint]];
    var person = [store classForName:@"foaf:Person"];
    [self assertTrue:[person isKindOfClass:[SPClass class]]];
    [self assert:@"foaf:Person" equals:[person className]];
}

@end
