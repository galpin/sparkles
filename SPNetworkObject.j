/*
 * SPNetworkObject.j
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

SPNetworkObjectConnectionTagDefault = 1;

/*!
    @class SPNetworkObject

    This is a base for classes that require a network connection. It contains a
    connection dispatch that was originally based on CPActiveRecord.
*/
@implementation SPNetworkObject : CPObject
{
    CPString _willLoadNotificationName @accessors(property=willLoadNotificationName);
    CPString _didLoadNotificationName @accessors(property=didLoadNotificationName);
    SPEndPoint _endPoint @accessors(property=endPoint);
    CPDictionary _userInfo;
}

/*!
    Parse the JSON response from the server.
    This method should be overriden by a subclass.
    @param aData the JSON response as a JSObject
    @param aTag the connection tag
*/
- (void)parseData:(JSObject)aData tag:(int)aTag
{
    // Override in subclass
}

/*!
    The SPARQL query that is executed automatically when an observer is added.
    This method should be overriden by a subclass.
    @return the SPARQL query as an instance of SPQueryBuilder
*/
- (SPQueryBuilder)buildQuery
{
    // Override in subclass
}

/*!
    An error occurred validation the HTTP response.
    @param aErrorObj the JSON that response
    @param aTag the connection tag
*/
- (void)raiseValidationError:(JSObject)aErrorObj tag:(int)aTag
{
    CPLog.info(@"Server refused SPARQL with: %@ for tag %d", aErrorObj, aTag);
}

#pragma mark -
#pragma mark CPURLConnection delegates
#pragma mark -

- (void)connection:(CPURLConnection)aConnection didReceiveResponse:(CPURLResponse)aResponse
{
    if([aResponse respondsToSelector:@selector(statusCode)] && [aResponse statusCode] > 200)
    {
	CPLog.info(@"SPARQL request failed with status code: %d for tag %d",
		   [aResponse statusCode], connection.postTag);
	aConnection.postTarget._invalidated = YES;
    }
}

- (void)connection:(CPURLConnection)aConnection didReceiveData:(CPString)aResponse
{
    if(!aConnection.postTarget || !aConnection.postTag)
	throw 'Invalid connection - please set aConnection.postTarget and aConnection.postTag!'

    try
    {
	var data = [aResponse objectFromJSON];
    }
    catch(anException)
    {
	CPLog.info(@"Could not load JSON");
	return;
    }

    CPLog(aResponse);

    if(aConnection.postTarget._invalidated)
    {
	aConnection.postTarget._invalidated = NO;
	return [aConnection.postTarget raiseValidationError:data tag:aConnection.postTag];
    }

    [self parseData:data tag:aConnection.postTag];
    [aConnection.postTarget didLoad:aConnection.postTag];
}

@end

@implementation SPNetworkObject (Loaders)

/*!
    Execute a SPARQL query on the current end point.
    @param aSPARQLQuery the SPARQL query to execute as a SPQueryBuilder
    @param aTag the connection tag
*/
- (void)executeQuery:(SPQueryBuilder)aSPARQLQuery tag:(int)aTag
{
    var request = [CPURLRequest requestWithURL:[[self endPoint] URL]
					SPARQL:[aSPARQLQuery description]];

    var connection = [CPURLConnection connectionWithRequest:request delegate:self];
    connection.postTarget = self;
    connection.postTag = aTag;

    [self willLoad:aTag];
}

/*!
    Execute the default query if necessary.
*/
- (void)loadIfNeeded
{
    // TODO implement a caching/timing mechanism.
    [self executeQuery:[self buildQuery] tag:SPNetworkObjectConnectionTagDefault];
}

/*!
    This method is called immeadiately before a query is executed.
    @param aTag the tag of the connection that is about to load
*/
- (void)willLoad:(int)aTag
{
    [self postNotification:_willLoadNotificationName];
}

/*!
    This method is called immeadiately after a query is successfully completed.
    @param aTag the tag of the connection that is complete
*/
- (void)didLoad:(int)aTag
{
    [self postNotification:_didLoadNotificationName];
}

@end

@implementation SPNetworkObject (Observers)

/*!
    Add an observer to this object. This will automatically trigger the query
    to be loaded by calling loadIfNeeded. A notification will be sent to the
    specified selector when the load is complete.
    @param anObserver the observing object
    @param anObserver the selector to be called when loading is complete
*/
- (void)addObserver:(id)anObserver selector:(SEL)aSelector
{
    [[CPNotificationCenter defaultCenter] addObserver:anObserver
					     selector:aSelector
						 name:_didLoadNotificationName
					       object:self];
    [self loadIfNeeded];
}

/*!
    Add an observer to this object. This will automatically trigger the query
    to be loaded by calling loadIfNeeded. A notification will be sent to the
    specified selector, including the given dictionary, when the load is complete.
    @param anObserver the observing object
    @param anObserver the selector to be called when loading is complete
    @param aUserInfo information about the notification that will be forwarded to the selector.
*/
- (void)addObserver:(id)anObserver selector:(SEL)aSelector userInfo:(CPDictionary)aUserInfo
{
    _userInfo = aUserInfo;
    [[CPNotificationCenter defaultCenter] addObserver:anObserver
					     selector:aSelector
						 name:_didLoadNotificationName
					       object:self];
    [self loadIfNeeded];
}

/*!
    Post a notification with the given name. Optionally includes userInfo if it was
    given to the observer.
*/
- (void)postNotification:(CPString)aNotificationName
{
    if(_userInfo)
	[[CPNotificationCenter defaultCenter] postNotificationName:aNotificationName
							    object:self
							  userInfo:_userInfo];
    else
	[[CPNotificationCenter defaultCenter] postNotificationName:aNotificationName
							    object:self];
}

@end
