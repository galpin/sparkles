/*
 * SPClass.j
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

@import <Foundation/CPObject.j>

@import "CPURLRequest-SPARQLAdditions.j"

SPClassCollectionWillLoad = @"SPClassCollectionWillLoad";
SPClassCollectionDidLoad = @"SPClassCollectionDidLoad";

/*!
    @class SPClass
    @brief This class is a representation of an RDF class.

    SPClass provides access to all resources of an RDF class on a specified endpoint.
*/
@implementation SPClass : CPObject
{
    CPString _className @accessors(property=className);
    SPEndPoint _endPoint @accessors(property=endPoint);
}

/*!
    Initializes the class with a specified RDF class name.
    @param aClassName the RDF class name
*/
- (id) initWithClassName:(CPString)aClassName
{
    self = [super init];

    if(self)
	_className = aClassName;

    return self;
}

/*!
    Initializes the class with a specified RDF type class and an instance of SPEndPoint.
    @param aClassName the RDF class name
    @param anEndPoint the SPEndPoint instance to use
*/
- (id) initWithClassName:(CPString)aClassName endPoint:(SPEndPoint)anEndPoint
{
    self = [self initWithClassName:aClassName];

    if(self)
	_endPoint = anEndPoint;

    return self;
}

/*!
   Gets all resources of this class on the current end point.
   @return an instance of SPCollectionResult for all instances of this class.
*/
- (SPCollectionResult) all
{
    return [[SPCollectionResult alloc] initWithQuery:[self _buildQuery] class:self];
}

- (SPQuery)_buildQuery
{
    var query = [SPQueryBuilder select:@"?uri"];
    [query where:SPTriple(@"?uri", @"a", _className)];
    [query orderBy:@"DESC(?uri)"];
    [query setDistinct:YES];

    return query;
}

@end
