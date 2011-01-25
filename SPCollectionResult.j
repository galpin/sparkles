/*
 * SPCollectionResult.j
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

SPCollectionResultWillLoad = @"SPCollectionResultWillLoad";
SPCollectionResultDidLoad = @"SPCollectionResultDidLoad";
SPCollectionResultConnectionTagCount = 10;

/*!
    @class SPCollectionResult
    @brief This class represents a collection of SPInstances' for a given class.

    SPCollectionResult provides access to a collection of SPInstances' that are
    the result of a specified query. This collection is lazy and wont execute
    until an observer has been registered (see SPNetworkObject).

    SPCollectionResult also supports preloading of a small number of properties
    in a single request (see setPreloadedProperties:).

    The class also supports fetching the number of results expected for the query
    before the query is executed. Whilst this is currently unused, in the future
    it might be used to circumvent "soft limits" on SPARQL endpoints by paginating
    results.
*/
@implementation SPCollectionResult : SPNetworkObject
{
    SPClass _class;
    CPQueryBuilder _query;
    CPArray _instances;
    CPDictionary _instancesDictionary;
    CPArray _preloadedProperties;
}

/*!
    Initialize the class with a specified query and class.
    @param aQuery the collection query as an instance of SPQueryBuilder
    @param aClass the class for this collection as an instance of SPClass
*/
- (id)initWithQuery:(SPQueryBuilder)aQuery class:aClass
{
    self = [super init];

    if(self)
    {
        _query = aQuery;
        _class = aClass;
        _instances = [CPArray array];
	_instancesDictionary = [CPDictionary dictionary];
	_preloadedProperties = [CPArray array];

	[self setWillLoadNotificationName:SPCollectionResultWillLoad];
	[self setDidLoadNotificationName:SPCollectionResultDidLoad];
	[self setEndPoint:[_class endPoint]];
    }

    return self;
}

/*!
    Preload the specified properties with the initial request for resources.
    @param firstProperty the first property to preload
*/
- (void)setPreloadedProperties:(CPString)firstProperty, ...
{
    [_preloadedProperties addObjectsFromArray: SPGetArgs(arguments, 2)];
}

/*!
    @return the total number of results in this collection
*/
- (int)count
{
    return [_instances count];
}

/*!
    @return an array of all instances in this collection
*/
- (CPArray)all
{
    return _instances;
}

/*!
    @return the first instance in this collection
*/
- (id)first
{
    return [_instances objectAtIndex:0];
}

@end

@implementation SPCollectionResult (SPNetworkObject)

// Override loadIfNeeded so we can inject the count first
- (void)loadIfNeeded
{
    [self executeQuery:[self buildCountQuery] tag:SPCollectionResultConnectionTagCount];
}

// Override didLoad: so we can start the proper query after the count
- (void)didLoad:(int)aTag
{
    if(aTag == SPCollectionResultConnectionTagCount)
	[super loadIfNeeded];
    else
	[super didLoad:aTag];
}

- (void)parseData:(JSObject)data tag:(int)aTag
{
    if(!data.head || !data.head.vars || !data.results || !data.results.bindings)
	throw "Invalid JSON RDF response.";

    if(aTag == SPCollectionResultConnectionTagCount)
    {
	var count = data.results.bindings[0].count.value;
	// TODO implement chunking if the count exceeds the SPARQL soft limit?
    }
    else
    {
	if(data.head.vars.indexOf("uri") < 0)
	    throw "Invalid JSON RDF response: missing uri variable.";

	for(var i = 0, count = data.results.bindings.length; i < count; i++)
	{
	    var binding = data.results.bindings[i];
	    var instance = [SPInstance instanceWithJSON:binding class:_class];

	    // Check if we already have an instance of this resource
	    // This might occur if a property cardinality is > 1
	    if(![_instancesDictionary containsKey:[instance URI]])
	    {
		[_instances addObject:instance];
		[_instancesDictionary setObject:instance forKey:[instance URI]];
	    }
	    else
		instance = [_instancesDictionary objectForKey:[instance URI]];

	    // Set any preloaded properties to this instance
	    if([_preloadedProperties count] > 0)
		[self parsePreloadedProperties:binding instance:instance];
	}
    }
}

- (SPQuery)buildQuery
{
    return _query;
}

@end

@implementation SPCollectionResult(PrivateMethods)

- (void)parsePreloadedProperties:(JSObject)aBinding instance:anInstance
{
    for(var i = 0, count = [_preloadedProperties count]; i < count; i++)
    {
	var property = [_preloadedProperties objectAtIndex:i];
	var variableName = [CPString stringWithFormat:@"property%d", i];

	if(aBinding[variableName])
	    [anInstance setObject:SPGetType(aBinding[variableName]) forProperty:property];
    }
}

- (SPQuery)buildCountQuery
{
    if([_preloadedProperties count] > 0)
	[self buildPreloadedPropertiesQuery];

    var countQuery = [SPQueryBuilder select:@"(COUNT(?g) as ?count)"];
    [countQuery where:SPNamed(@"?g", _query._defaultGraph)];

    return countQuery;
}

- (void)buildPreloadedPropertiesQuery
{
    // In order to preload properties, we modify the existing SPARQL query so that
    // we include a "?properyN" variable for each and then an OPTIONAL {} match on
    // the property for each resource

    // TODO use and return a copy of _query rather than modify the existing query
    for(var i = 0, count = [_preloadedProperties count]; i < count; i++)
    {
	var property = [_preloadedProperties objectAtIndex:i];
	var variableName = [CPString stringWithFormat:@"?property%d", i];

	[[_query variables] addObject:variableName];

	[_query where:SPOptional(SPTriple(@"?uri", property, variableName))];
    }
}

@end

