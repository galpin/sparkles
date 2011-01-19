/*
 * SPClassTest.j
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

@implementation SPClassTest : OJTestCase

- (void)initWithClassName
{
    var instances = [CPClass initWithClassName:@"foaf:Person"];
    [self assertTrue:instances];
    [self assert:@"foaf:person" equals:[instances className]];
    [self assertFalse:[instances endPoint]];
}

- (void)testInitWithClassNameAndEndPoint
{
    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var instances = [[SPClass alloc] initWithClassName:@"foaf:Person" endPoint:endPoint];
    [self assertTrue:instances];
    [self assert:@"foaf:Person" equals:[instances className]];
    [self assert:endPoint equals:[instances endPoint]];
}

- (void)testAll
{
    var endPoint = [SPEndPoint endPointWithString:@"http://example.org/sparql"];
    var person = [[SPClass alloc] initWithClassName:@"foaf:Person" endPoint:endPoint];
    var instances = [person all];
    [self assertTrue:[instances isKindOfClass:[SPCollectionResult class]]];
}

@end
