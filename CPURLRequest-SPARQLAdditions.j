/*
 * CPURLRequest-SPARQLAdditions.j
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

@implementation CPURLRequest (SPARQL)


/*!
   Create a CPURLRequest for a specified URL and SPARQL query. The correct
   HTTP headers are set automatically.
   @param theURL the URL to request
   @param theSPARQL the SPARQL query as a string
*/
+ (id)requestWithURL:(CPURL)theURL SPARQL:(CPString)theSPARQL
{
    var request = [CPURLRequest requestWithURL:theURL];
    var body = [CPString stringWithFormat:@"query=%@", encodeURIComponent(theSPARQL)];

    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:[body length] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];

    return request;
}

@end
