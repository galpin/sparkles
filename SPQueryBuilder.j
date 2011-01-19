/*
 * SPQueryBuilder.j
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
    Create a new triple.
*/
function SPTriple(s, p, o)
{
    return [[SPQueryTriple alloc] initWithSubject:s predicate:p object:o];
}

/*!
    Create a new optional graph. This function is variadic where each arguent is
    a node in the graph.
*/
function SPOptional()
{
    var message = new Array();
    message[0] = [SPQueryOptionalGroup alloc];
    message[1] = @selector(initWithGraph:);
    return objj_msgSend.apply(nil, message.concat(SPGetArgs(arguments, 0)));
}

/*!
    Create a new named graph. This function is variadic where each argument after
    name is a name in the graph.
    @param aName the graph name.
*/
function SPNamed(aName)
{
    var message = new Array();
    message[0] = [SPQueryNamedGroup alloc];
    message[1] = @selector(initWithName:withGraph:);
    message[2] = aName;
    return objj_msgSend.apply(nil, message.concat(SPGetArgs(arguments, 1)));
}

/*!
    Create a new FILTER function call.
    @param functionCall the complete function call, e.g. regex(?var, '^foo')
*/
function SPFilter(aFunctionCall)
{
    return [[SPQueryFilter alloc] initWithFunctionCall:aFunctionCall];
}

/*!
    Create a new graph. This function is variadic where each argument is a
    node in the graph.
*/
function SPGraph()
{
    var message = new Array();
    message[0] = [SPQueryGraph alloc];
    message[1] = @selector(initWithGraph:);
    return objj_msgSend.apply(nil, message.concat(SPGetArgs(arguments, 0)));
}

/*!
    Create a new graph. This function is variadic where each argument is a
    node in the graph.
*/
function SPUnion()
{
    var message = new Array();
    message[0] = [SPQueryUnion alloc];
    message[1] = @selector(initWithGraph:);
    return objj_msgSend.apply(nil, message.concat(SPGetArgs(arguments, 0)));
}

/*!
    Utility function for constraining a variable to a particular language.
    Gets expanded in form: aVariable FILTER(lang(aVariable) = 'aLanguage')
*/
function SPLanguage(aVariable, aLanguage)
{
    return [CPString stringWithFormat:@"%@ FILTER(lang(%@) = '%@')",
		     aVariable, aVariable, aLanguage];
}

/*!
    @class SPQueryTriple
    @brief This class represents a triple. Consider using SPTriple() instead.
*/
@implementation SPQueryTriple : CPObject
{
    CPString _subject @accessors(property=subject, readonly);
    CPString _predicate @accessors(property=predicate, readonly);
    CPString _object @accessors(property=object, readonly);
}

- (id)initWithSubject:aSubject predicate:aPredicate object:aObject
{
    self = [super init];

    if(self)
    {
	_subject = aSubject;
	_predicate = aPredicate;
	_object = aObject;
    }

    return self;
}

- (CPArray)namespacePrefixes
{
    var prefixes = [[CPArray alloc] init],
	qName;

    if(qName = SPSplitQualifiedName(_subject))
	[prefixes addObject:qName.prefix];

    if(qName = SPSplitQualifiedName(_predicate))
	[prefixes addObject:qName.prefix];

    if(qName = SPSplitQualifiedName(_object))
	[prefixes addObject:qName.prefix];

    return prefixes;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@ %@ %@ .", _subject, _predicate, _object];
}

@end

/*!
    @class SPQueryGraph
    @brief This class represents a graph. Consider using SPGraph() instead.
*/
// Based on the ConcreteArray subclass in CPArrayTest.j
@implementation SPQueryGraph : CPArray
{
    Array _array;
    CPDictionary _prefixes;
}

- (id)initWithGraph:(id)firstNode, ...
{
    self = [self init];

    if(self)
    {
	_array = SPGetArgs(arguments, 2);
	_prefixes = [[CPDictionary alloc] init];
    }

    return self;
}

- (id)init
{
    self = [super init];

    if (self)
    {
        _array = [];
    }

    return self;
}

- (CPUInteger)count
{
    return _array.length;
}

- (id)objectAtIndex:(CPUInteger)anIndex
{
    if (anIndex < 0 || anIndex >= [self count])
	throw "range error";

    return _array[anIndex];
}

- (void)addObject:(id)anObject
{
    [_array addObject:anObject];
}

- (void)addObjectsFromArray:(CPArray)anArray
{
    [_array addObjectsFromArray:anArray];
}

- (CPArray)namespacePrefixes
{
    var prefixes = [CPArray array],
	enumerator = [self objectEnumerator],
	node;

    while(node = [enumerator nextObject])
	[prefixes addObjectsFromArray:[node namespacePrefixes]];

    return prefixes;
}

- (CPString)description
{
    var lines = [CPArray array],
	enumerator = [self objectEnumerator],
	object;

    [lines addObject:@"{"];

    while(object = [enumerator nextObject])
	[lines addObject:[object description]];

    [lines addObject:@"}"];

    return [lines componentsJoinedByString:@"\n"];
}

@end

/*!
    @class SPQueryOptionalGroup
    @brief This class represents an optional group. Consider using SPOptional() instead.
*/
@implementation SPQueryOptionalGroup : SPQueryGraph
{
}

- (CPString)description
{
    return [CPString stringWithFormat:@"OPTIONAL\n%@", [super description]];
}

@end

/*!
    @class SPQueryNamedGroup
    @brief This class represents a named graph. Consider using SPNamed() instead.
*/
@implementation SPQueryNamedGroup : SPQueryGraph
{
    CPString _name @accessors(property=name, readonly);
}

- (id)initWithName:(CPString)theName withGraph:(id)firstNode, ...
{
    // forward the arguments to the super constructor
    var message = new Array();
    message[0] = self;
    message[1] = @selector(initWithGraph:);
    self = objj_msgSend.apply(nil, message.concat(SPGetArgs(arguments, 3)));

    if(self)
	_name = theName;

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"GRAPH\n%@\n%@", _name, [super description]];
}

@end

/*!
    @class SPQueryUnion
    @brief This class represents a matching alternative using UNION. Consider using
    SPUnion() instead.
*/
@implementation SPQueryUnion : SPQueryGraph
{
}

- (CPString)description
{
    return [_array componentsJoinedByString:@"\nUNION\n"];
}

@end

/*!
    @class SPQueryFilter
    @brief This class a FILTER function call. Consider using SPFilter() instead.
*/
@implementation SPQueryFilter : CPObject
{
    CPString _functionCall (property=functionCall, readonly);
}

- (id)initWithFunctionCall:(CPString)theFunctionCall
{
    self = [super init];

    if(self)
	_functionCall = theFunctionCall;

    return self;
}


- (CPArray)namespacePrefixes
{
    return [CPArray array];
}


- (CPString)description
{
    return [CPString stringWithFormat:@"FILTER %@", _functionCall];
}

@end

_SPQueryBuilderTypeSelect =  1;
_SPQueryBuilderTypeConstruct =  2;
_SPQueryBuilderTypeAsk =  3;
_SPQueryBuilderTypeDescribe =  4;
_SPQueryBuilderNoOffset = -1;
_SPQueryBuilderNoLimit = -1;

/*!
    @class SPQueryBuilder
    @brief Generate SPARQL queries in a programatic manor.

    This class provides a mechanism for generating SPARQL queries
    in a programatic manor.

    For more information on the SPARQL Query Language, see
    http://www.w3.org/TR/rdf-sparql-query/.
*/
@implementation SPQueryBuilder : CPObject
{
    BOOL _isDistinct @accessors(getter=isDistinct, setter=setDistinct:);
    BOOL _isReduced @accessors(getter=isReduced, setter=setReduced:);
    int _offset @accessors(property=offset);
    int _limit @accessors(property=limit);
    CPString _emptyNamespace @accessors(property=emptyNamespace);
    CPArray _variables @accessors(property=variables);

    CPDictionary _prefixes;
    SPQueryGraph _defaultGraph;
    SPQueryGraph _constructGraph;
    CPArray _orderByConditions;
    CPArray _from;
    CPArray _fromNamed;
    int _type;
}

// Do not instantiate manually - use one of the class methods
- (id) initWithQueryBuilderType:(int)aType
{
    self = [super init];

    if(self)
    {
        _type = aType;

        _prefixes = [[CPDictionary alloc] init];
        _defaultGraph = [[SPQueryGraph alloc] init];
	_orderByConditions = [CPArray array];
	_from = [CPArray array];
	_fromNamed = [CPArray array];

	_offset = _SPQueryBuilderNoOffset;
	_limit = _SPQueryBuilderNoLimit;
    }

    return self;
}

// Do not instantiate manually - use one of the class methods
- (id) initWithQueryBuilderType:(int)aType variables:(CPArray)anArrayOfVariables
{
    self = [self initWithQueryBuilderType:aType];

    if(self)
	_variables = anArrayOfVariables;

    return self;
}

// Do not instantiate manually - use one of the class methods
- (id) initWithQueryBuilderType:(int)aType constructGraph:(SPQueryGraph)aConstructGraph
{
    self = [self initWithQueryBuilderType:aType];

    if(self)
	_constructGraph = aConstructGraph;

    return self;
}

// Do not instantiate manually - use one of the class methods
- (id) initWithQueryBuilderType:(int)aType defaultGraph:(SPQueryGraph)aGraph
{
    self = [self initWithQueryBuilderType:aType];

    if(self)
	_defaultGraph = aGraph;

    return self;
}

/*!
    Create a new SELECT query.
    @param firstVariable the variables that will be added to the query.
*/
+ (id)select:(id)firstVariable, ...
{
    var arguments = SPGetArgs(arguments, 2);
    return [[SPQueryBuilder alloc] initWithQueryBuilderType:_SPQueryBuilderTypeSelect
						  variables:arguments];
}

/*!
    Create a new CONSTRUCT query.
    @param firstNode the nodes that will be added to the CONSTRUCT graph.
*/
+ (id)construct:(id)firstNode, ...
{
    var arguments = SPGraph.apply(nil, SPGetArgs(arguments, 2));
    return [[SPQueryBuilder alloc] initWithQueryBuilderType:_SPQueryBuilderTypeConstruct
					     constructGraph:arguments];
}

/*!
    Create a new ASK query.
    @param firstNode the nodes that will be added to the CONSTRUCT graph.
*/
+ (id)ask:(id)firstNode, ...
{
    var arguments = SPGraph.apply(nil, SPGetArgs(arguments, 2));
    return [[SPQueryBuilder alloc] initWithQueryBuilderType:_SPQueryBuilderTypeAsk
					       defaultGraph:arguments];
}

/*!
    Create a new DESCRIBE query.
    @param firstNode the nodes that will be added to the CONSTRUCT graph.
*/
+ (id)describe:(id)firstVariable, ...
{
    var arguments = SPGetArgs(arguments, 2);
    return [[SPQueryBuilder alloc] initWithQueryBuilderType:_SPQueryBuilderTypeDescribe
						  variables:arguments];
}

/*!
    Set the WHERE clause of a query.
    @param firstNode the nodes that will be added to the WHERE clause graph.
*/
- (id)where:(id)firstNode, ...
{
    [_defaultGraph addObjectsFromArray: SPGetArgs(arguments, 2)];
    return self;
}

/*!
    Add an ORDER BY condition to the query.
    @param firstCondition the conditions that will be added to the query.
*/
- (id)orderBy:(id)firstCondition, ...
{
    [_orderByConditions addObjectsFromArray:SPGetArgs(arguments, 2)];
}

- (void)from:(CPString)firstURI, ...
{
    [_from addObjectsFromArray:SPGetArgs(arguments, 2)];
}

- (void)fromNamed:(CPString)firstURI, ...
{
    [_fromNamed addObjectsFromArray:SPGetArgs(arguments, 2)];
}

- (CPString)description
{
    switch(_type)
    {
        case _SPQueryBuilderTypeSelect:    return [self _createSelectQuery];
        case _SPQueryBuilderTypeConstruct: return [self _createConstructQuery];
        case _SPQueryBuilderTypeAsk:       return [self _createAskQuery];
        case _SPQueryBuilderTypeDescribe:  return [self _createDescribeQuery];
    }
}

- (void)_addPrefixes:(CPArray)arrayOfPrefixes
{
    var enumerator = [arrayOfPrefixes objectEnumerator],
	prefix;

    while(prefix = [enumerator nextObject])
    {
	var namespace = [[SPNamespaceManager sharedManager] namespaceForPrefix:prefix];

	if(namespace)
	    [_prefixes setObject:namespace forKey:prefix];
    }
}

@end

@implementation SPQueryBuilder (QueryCreation)

- (CPString)_createSelectQuery
{
    var lines = [CPArray array];

    [lines addObject:@"SELECT"];
    [self _createDuplicateSolutions:lines];
    [self _createVariables:lines];

    [self _createDatasetClause:lines];
    [self _createWhereClause:lines];
    [self _createSolutionModifiers:lines];
    [self _createNamespaceDeclations:lines];

    return [lines componentsJoinedByString:@"\n"];
}

- (CPString)_createConstructQuery
{
    var lines = [CPArray array];

    [lines addObject:@"CONSTRUCT"];
    [self _createGraphClause:lines graph:_constructGraph];
    [self _createVariables:lines];
    [self _createDatasetClause:lines];
    [self _createWhereClause:lines];
    [self _createSolutionModifiers:lines];
    [self _createNamespaceDeclations:lines];

    return [lines componentsJoinedByString:@"\n"];
}

- (CPString)_createAskQuery
{
    var lines = [CPArray array];

    [lines addObject:@"ASK"];
    [self _createDatasetClause:lines];
    [self _createGraphClause:lines graph:_defaultGraph];
    [self _createNamespaceDeclations:lines];

    return [lines componentsJoinedByString:@"\n"];
}


- (CPString)_createDescribeQuery
{
    var lines = [CPArray array];

    [lines addObject:@"DESCRIBE"];
    [self _createVariables:lines];
    [self _createDatasetClause:lines];
    [self _createWhereClause:lines];
    [self _createSolutionModifiers:lines];
    [self _createNamespaceDeclations:lines];

    return [lines componentsJoinedByString:@"\n"];
}

- (void)_createDatasetClause:(CPArray)arrayOfLines
{
    var enumerator = [_from objectEnumerator],
	uri;

    if([_from count] > 0)
    {
	while(uri = [enumerator nextObject])
	    [arrayOfLines addObject:[CPString stringWithFormat:@"FROM\n%@", uri]];
    }

    enumerator = [_fromNamed objectEnumerator];

    if([_fromNamed count] > 0)
    {
	while(uri = [enumerator nextObject])
	    [arrayOfLines addObject:[CPString stringWithFormat:@"FROM NAMED\n%@", uri]];
    }
}

- (void)_createDuplicateSolutions:(CPArray)arrayOfLines
{
    if(_isDistinct)
	[arrayOfLines addObject:@"DISTINCT"];
    if(_isReduced)
	[arrayOfLines addObject:@"REDUCED"];
}

- (void)_createVariables:(CPArray)arrayOfLines
{
    if([_variables count] > 0)
	[arrayOfLines addObject:[_variables componentsJoinedByString:@" "]];
}

- (void)_createWhereClause:(CPArray)arrayOfLines
{
    if([_defaultGraph count] > 0)
	[arrayOfLines addObject: @"WHERE"];
    [self _createGraphClause:arrayOfLines graph:_defaultGraph];
}

-(void)_createGraphClause:(CPArray)arrayOfLines graph:(SPQueryGraph)aGraph
{
    if([aGraph count] > 0)
    {
	[arrayOfLines addObject:[aGraph description]];
	[self _addPrefixes:[aGraph namespacePrefixes]];
    }
}

-(void)_createSolutionModifiers:(CPArray)arrayOfLines
{
    if([_orderByConditions count] > 0)
	[arrayOfLines addObject:[CPString stringWithFormat:@"ORDER BY %@",
					  [_orderByConditions componentsJoinedByString:@" "]]];

    if(_limit != _SPQueryBuilderNoLimit)
	[arrayOfLines addObject:[CPString stringWithFormat:@"LIMIT %d", _limit]];

    if(_offset != _SPQueryBuilderNoOffset)
	[arrayOfLines addObject:[CPString stringWithFormat:@"OFFSET %d", _offset]];
}

- (void)_createNamespaceDeclations:(CPArray)arrayOfLines
{
    // overwrite namespace prefixes with custom namespaces
    [_prefixes addEntriesFromDictionary:[SPNamespaceManager sharedManager]];

    var enumerator = [_prefixes keyEnumerator],
	key;

    while(key = [enumerator nextObject])
    {
	var line = [CPString stringWithFormat:@"PREFIX %@: <%@>",
			     key, [_prefixes objectForKey:key]];
        [arrayOfLines insertObject:line atIndex:0];
    }

    if(_emptyNamespace)
    {
	var line = [CPString stringWithFormat:@"PREFIX : <%@>", _emptyNamespace];
        [arrayOfLines insertObject:line atIndex:0];
    }
}

- (void)_createVariables:(CPArray)arrayOfLines
{
    if([_variables count] > 0)
	[arrayOfLines addObject:[_variables componentsJoinedByString:@" "]];
}

@end

/*!
    @param the offset that variadic arguments start at.
    @return the the variadic arguments to an objective-j function.
*/
function SPGetArgs(arguments, offset)
{
    return [].splice.call(arguments, offset);
}
