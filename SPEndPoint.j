/*
 * SPEndPoint.j
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

/*!
    @class SPEndPoint
    @brief This class represents a connection to a SPARQL endpoint over HTTP.
*/
@implementation SPEndPoint : CPObject
{
    CPURL _URL @accessors(property=URL, readonly);
}

/*!
    Initializes the end point with a specified URL.
    @param aURL the instance CPURL for this endpoint
*/
- (id)initWithURL:(CPURL)aURL
{
    self = [super init];

    if(self)
        _URL = aURL;

    return self;
}

/*!
    Creates a new SPEndPoint with a specified string.
    @param aURLString the URL for this endpoint as a string
*/
+ (id)endPointWithString:(CPString)aURLString
{
    return [[SPEndPoint alloc] initWithURL:[CPURL URLWithString:aURLString]];
}

/*!
    @param aClassName the RDF type, e.g. foaf:Person
    @return an instance of CPClass for the specified RDF type
*/
- (CPClass)classForName:(CPString)aClassName
{
    return [[SPClass alloc] initWithClassName:aClassName endPoint:self];
}

@end
