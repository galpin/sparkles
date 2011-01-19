/*
 * SPNamespaceManager.j
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

@import "SPDefaultNamespaces.j"

@import <Foundation/CPDictionary.j>

SPNamespaces = nil;

/*!
    @class SPNamespaceManager

    SPNamespaceManager provides a mechanism for maintaing a list of namespace/prefix
    pairs throughout the application.

    A significant list of default namespaces (from www.prefix.cc) is automatically
    included (see SPDefaultNamespaces.j). This is in addition to the ability to
    register custom namespaces.

    This class should be considered a singleton and accessed via the class method
    [SPNamespaceManager sharedManager].
*/
@implementation SPNamespaceManager : CPDictionary
{
}

/*!
    @return the shared singleton instance of SPNamespaceManager
*/
+ (SPNamespaceManager)sharedManager
{
    if(!SPNamespaces)
        SPNamespaces = [[SPNamespaceManager alloc] init];

    return SPNamespaces;
}

/*!
    Register a custom namespace and prefix.

    @param aNamespace the namespace URI.
    @param aPrefix the prefix for this namespace.
*/
- (void)addNamespace:(CPString)aNamespace forPrefix:(CPString)aPrefix
{
    [self setObject:aNamespace forKey:aPrefix];
}

/*!
    @param aPrefix the prefix for this namespace.
    @return the full namespace URI for this prefix. Custom namespaces (explicitly
    registered with this instance) are given precedence over default names. Returns
    nil if no namespace with the given prefix exists.
*/
- (CPString)namespaceForPrefix:(CPString)aPrefix
{
    if([self containsKey:aPrefix])
        return [self objectForKey:aPrefix];

    return SPDefaultNamespaces[aPrefix];
}

/*!
    Expands a Qualified Name (or QName) into an absolute namespace URI.

    @param aQName the qualified name to expand (e.g. "foaf:mbox").
    @return the absolute namsepace URI as a string or aQName if no matching namespace prefix
    could be found or is aQName was not a actually a QName.
*/
- (CPString)expandQualifiedName:(CPString)aQName
{
    var qname = SPSplitQualifiedName(aQName);

    if(qname)
    {
	var namespace = [self namespaceForPrefix:qname.prefix];

	if(namespace)
	    return [namespace stringByAppendingString:qname.localName];
    }

    return aQName;
}

@end

/*!
    Split a Qualified Name (or QName) into a object consisting of its "prefix"
    and "localName".

    For example, the QName "foaf:mbox", will be split as follows:

    <pre>{ "prefix": "foaf", "localName": "mbox" }</pre>.

    @return The object or false if the given string is not a qName.
*/
function SPSplitQualifiedName(aStr)
{
    var re = /^([A-z0-9_-]+):([A-z0-9_-]+)$/;
    var matches = re.exec(aStr);

    if(matches)
        return { "prefix": matches[1], "localName": matches[2] };

    return false;
}
