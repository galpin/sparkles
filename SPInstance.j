/*
 * SPInstance.j
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

SPInstanceWillLoad = @"SPInstanceWillLoad"
SPInstanceDidLoad = @"SPInstanceDidLoad"

/*!
    @class SPInstance
    @brief This class represents a single instance (resource) of a specific RDF class.
*/
@implementation SPInstance : SPNetworkObject
{
    SPClass _class;
    CPString _URI @accessors(property=URI, readonly);
    CPDictionary _properties @accessors(property=properties);
    CPDictionary _inverse;
}

/*!
    Initializes the instance with a specified resource URI but no class.
    @param aURI the resource URI
*/
- (id)initWithURI:(CPString)aURI
{
    self = [super init];

    if(self)
    {
	[self setWillLoadNotificationName:SPInstanceWillLoad];
	[self setDidLoadNotificationName:SPInstanceDidLoad];

        _URI = aURI;
	_properties = [CPDictionary dictionary];
        _inverse = [CPDictionary dictionary];
    }

    return self;
}

/*!
    Initializes the instance with a specified resource URI and class
    @param aURI the resource URI as a string
    @param aClass the resource class as an instance of SPClass
*/
- (id)initWithURI:(CPString)aURI forClass:(SPClass)aClass
{
    self = [self initWithURI:aURI];

    if(self)
    {
	[self setEndPoint:[aClass endPoint]];

	_class = aClass;
    }

    return self;
}

/*!
    Initializes the instance with a specified resource URI and class
    @param aURI the resource URI as a string
    @param aEndPoint the endpoint for this resource
*/
- (id)initWithURI:(CPString)aURI endPoint:(SPEndPoint)aEndPoint
{
    self = [self initWithURI:aURI];

    if(self)
	[self setEndPoint:aEndPoint];

    return self;
}

/*!
    Initializes an instance for a specified class from a SPARQL JSON
    resource in the form:

    <pre>
    {
        "uri":
	{
	    "type": "uri",
	    "value": "http://example.org/Alice/"
	}
    }
    </pre>

    @param aURI the resource URI as a string
    @param aClass the resource class as an instance of SPClass
*/
+ (id)instanceWithJSON:(JSObject)aJSON class:(SPClass)aClass
{
    if(!aJSON.uri)
        throw "missing URI";

    return [[SPInstance alloc] initWithURI:aJSON.uri.value forClass:aClass];
}

/*!
    Initializes an instance for an unspecified class from a SPARQL JSON
    resource in the form:

    <pre>
    {
        "uri":
	{
	    "type": "uri",
	    "value": "http://example.org/Alice/"
	}
    }
    </pre>

    @param aURI the resource URI as a string
*/
+ (id)instanceWithJSON:(JSObject)aJSON
{
    if(!aJSON.uri)
        throw "missing URI";

    return [[SPInstance alloc] initWithURI:aJSON.uri.value];
}

/*!
    Initializes an instance for a specified class from a SPARQL JSON
    resource in the form:

    <pre>
    {
        "uri":
	{
	    "type": "uri",
	    "value": "http://example.org/Alice/"
	}
    }
    </pre>

    @param aURI the resource URI as a string
    @param endPoint the endPoint for this resource
*/
+ (id)instanceWithJSON:(JSObject)aJSON endPoint:(SPEndPoint)aEndPoint
{
    if(!aJSON.uri)
        throw "missing URI";

    return [[SPInstance alloc] initWithURI:aJSON.uri.value endPoint:aEndPoint];
}


/*!
    Sets the specified property of this instance to a given object.
    @param aObject the value of this property (a subclass of SPLiteral or SPInstance)
    @param aURI the property URI as a string
*/
- (void)setObject:(id)aObject forProperty:(CPString)aURI
{
    aURI = [[SPNamespaceManager sharedManager] expandQualifiedName:aURI];

    if([_properties containsKey:aURI])
    {
	// the cardinality of this property is now > 1 therefore we crudely
	// replace the actual property with an array or append the existing

	var existingObject = [_properties objectForKey:aURI];

	if(![existingObject isKindOfClass:[CPArray class]])
	    aObject = [CPArray arrayWithObjects:existingObject, aObject];
	else
	    aObject = [existingObject arrayByAddingObject:aObject];
    }

    [_properties setObject:aObject forKey:aURI];
}

/*!
    Gets the value of a specified property.
    @param aURI the property URI as a string (can also be a QName, e.g. "foaf:mbox")
    @return the value of this property or nil if it does not exist
*/
- (id)property:(CPString)aURI
{
    return [_properties objectForKey:[[SPNamespaceManager sharedManager] expandQualifiedName:aURI]];
}

/*!
    Gets a collection of results that are an inverse relationship for this property.
    Results are cached - subsequent calls will be loaded. TEST
    FIXME: documentation.
*/
- (SPCollectionResult)inverse:(CPString)aURI
{
    aURI = [[SPNamespaceManager sharedManager] expandQualifiedName:aURI];

    if(![_inverse containsKey:aURI])
    {
        var query = [SPQueryBuilder select:@"?uri"];
        [query where:SPTriple("?uri", [CPString stringWithFormat:@"<%@>", aURI],
                              [CPString stringWithFormat:@"<%@>", _URI])];

        var collection = [[SPCollectionResult alloc] initWithQuery:query
                                                          endPoint:[self endPoint]];
        [_inverse setObject:collection forKey:aURI];
    }

    return [_inverse objectForKey:aURI];
}

@end

@implementation SPInstance (SPNetworkObject)

- (CPString)description
{
    return _URI;
}

- (void)parseData:(JSObject)aData tag:(int)aTag
{
    if(!aData.head || !aData.head.vars || !aData.results || !aData.results.bindings)
	throw "Invalid JSON RDF response.";

    if(aData.head.vars.indexOf("object") < 0 || aData.head.vars.indexOf("predicate") < 0)
	throw "Invalid JSON RDF response: missing uri variable.";

    // Clear all existing preloaded properties to avoid duplicates.
    [_properties removeAllObjects];

    for(var i = 0, count = aData.results.bindings.length; i < count; i++)
    {
	var binding = aData.results.bindings[i];

	[self setObject:SPGetType(binding.object)
	    forProperty:[SPGetType(binding.predicate) description]];
    }
}

- (SPQuery)buildQuery
{
    var query = [SPQueryBuilder select:@"?predicate", @"?object"];
    [query where:SPTriple([CPString stringWithFormat:@"<%@>", _URI], @"?predicate", @"?object")];

    return query;
}

@end
