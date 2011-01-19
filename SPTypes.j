/*
 * SPTypes.j
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
    @class SPLiteral
    @brief A base class for all literal types.
*/
@implementation SPLiteral : CPObject
{
    id _value @accessors(property=value);
}

- (id)initWithValue:(id)aValue
{
    self = [super init];

    if(self)
	_value = aValue;

    return self;
}

- (CPString)description
{
    return [CPString stringWithFormat:@"%@", [self value]];
}

@end

/*!
    @class SPLiteralURI
    @brief This represents a literal resource URI.
*/
@implementation SPLiteralURI : SPLiteral

@end

/*!
    @class SPPlainLiteral
    @brief This represents a plain literal string with an optional language.

    For more details, see http://www.w3.org/TR/rdf-concepts/#section-Literals
*/
@implementation SPPlainLiteral : SPLiteral
{
    CPString _language @accessors(property=language);
}

@end

/*!
    @class SPTypedLiteral
    @brief This represents a literal string combined with a datatype URI.

    This class makes no attempt to map the lexical string to the specified type.

    Concrete subclasses of SPTypedLiteral are provided for the primitive types
    specified in the XML Schema. Custom subclasses should override the value getter
    and provide an appropriate lexical-to-value mapping.

    For more details, see http://www.w3.org/TR/rdf-concepts/#dfn-typed-literal
*/
@implementation SPTypedLiteral : SPLiteral
{
    CPString _datatype @accessors(property=datatype);
}

- (id)initWithValue:(id)aValue forDatatype:(CPString)aDatatype
{
    self = [super initWithValue:aValue];

    if(self)
	_datatype = aDatatype;

    return self;
}

@end

/*!
    @class SPLiteralBoolean
    @brief This represents a xsd:boolean literal.
*/
@implementation SPLiteralBoolean : SPTypedLiteral

- (id)value
{
    return (_value == "true" || _value == "1") ? YES : NO;
}

@end


/*!
    @class SPLiteralDouble
    @brief This represents a xsd:double literal.
*/
@implementation SPLiteralDouble : SPTypedLiteral

- (id)value
{
    return parseFloat(_value);
}

@end

/*!
    @class SPLiteralInteger
    @brief This represents a xsd:integer literal.
*/
@implementation SPLiteralInteger : SPTypedLiteral

- (id)value
{
    return parseInt(_value);
}

@end

/*!
    Creates a concrete class for a RDF JSON binding in the form:

    <pre>
        { "type": "T", "value": "V" }
    </pre>

    where T can be either "uri" (SPInstance), "literal" (SPPlainLiteral)
    or "typed-literal" (SPTypedLiteral).

    Typed literals are instantiated as a concrete subclass of SPTypedLiteral
    where possible and according to _SPTypedLiteralClasses.

    @return a subclass for SPLiteral.
*/
function SPGetType(aJSONBinding)
{
    if(!aJSONBinding.type || !aJSONBinding.value)
	throw "Invalid JSON binding";

    var type;

    if(aJSONBinding.type == "uri")
    {
	type = [[SPLiteralURI alloc] initWithValue:aJSONBinding.value];
    }
    else if(aJSONBinding.type == "literal")
    {
	type = [[SPPlainLiteral alloc] initWithValue:aJSONBinding.value];

	if(aJSONBinding["xml:lang"])
	    [type setLanguage:aJSONBinding["xml:lang"]];
    }
    else if(aJSONBinding.type == "typed-literal" && aJSONBinding["datatype"])
    {
	var datatypeClass = _SPTypedLiteralClasses[aJSONBinding["datatype"]];

	if(datatypeClass)
	    type = [[datatypeClass alloc] initWithValue:aJSONBinding.value
					    forDatatype:aJSONBinding["datatype"]];
	else
	    type = [[SPTypedLiteral alloc] initWithValue:aJSONBinding.value
					     forDatatype:aJSONBinding["datatype"]];
    }
    // TODO bnode support

    return type;
}

/*!
    Register a new (or override) a SPTypedLiteral subclass association at runtime.
*/
function SPRegisterTypedLiteral(aURI, aClass)
{
    _SPTypedLiteralClasses[aURI] = aClass;
}

_SPTypedLiteralClasses =
{
    "http://www.w3.org/2001/XMLSchema#boolean": SPLiteralBoolean,
    "http://www.w3.org/2001/XMLSchema#double": SPLiteralDouble,
    "http://www.w3.org/2001/XMLSchema#integer": SPLiteralInteger,
}

// TODO map all derived integers to integer
