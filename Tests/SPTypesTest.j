/*
 * SPInstanceTest.j
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

@implementation SPTypesTest : OJTestCase

- (void)testLiteralURI
{
    var type = SPGetType({ "type": "uri", "value": "http://example.org/Alice/" });
    [self assert:[SPLiteralURI class] equals:[type class]];
}


- (void)testLiteral
{
    var type;

    type = SPGetType({ "type": "literal", "value": "I love coffee." });
    [self assert:[SPPlainLiteral class] equals:[type class]];
    [self assert:@"I love coffee." equals:[type value]];
    [self assert:nil equals:[type language]];

    type = SPGetType({ "type": "literal", "value": "J\'adore le café.", "xml:lang": "fr" });
    [self assert:[SPPlainLiteral class] equals:[type class]];
    [self assert:@"J\'adore le café." equals:[type value]];
    [self assert:@"fr" equals:[type language]];
}

- (void)testUnknownTypedLiteral
{
    var type;

    type = SPGetType({ "type": "typed-literal", "value": "This is foobar.", "datatype": "http://example.org/types#foo" });
    [self assert:[SPTypedLiteral class] equals:[type class]];
    [self assert:@"This is foobar." equals:[type value]];
    [self assert:@"http://example.org/types#foo" equals:[type datatype]];
}

- (void)testBoolean
{
    var type;

    type = SPGetType({ "type": "typed-literal", "value": "true", "datatype": "http://www.w3.org/2001/XMLSchema#boolean" });
    [self assert:[SPLiteralBoolean class] equals:[type class]];
    [self assertTrue:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "false", "datatype": "http://www.w3.org/2001/XMLSchema#boolean" });
    [self assert:[SPLiteralBoolean class] equals:[type class]];
    [self assertFalse:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "1", "datatype": "http://www.w3.org/2001/XMLSchema#boolean" });
    [self assert:[SPLiteralBoolean class] equals:[type class]];
    [self assertTrue:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "0", "datatype": "http://www.w3.org/2001/XMLSchema#boolean" });
    [self assert:[SPLiteralBoolean class] equals:[type class]];
    [self assertFalse:[type value]];
}

- (void)testDouble
{
    var type;

    type = SPGetType({ "type": "typed-literal", "value": "-0.66", "datatype": "http://www.w3.org/2001/XMLSchema#double" });
    [self assert:[SPLiteralDouble class] equals:[type class]];
    [self assert:-0.66 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "6.66", "datatype": "http://www.w3.org/2001/XMLSchema#double" });
    [self assert:[SPLiteralDouble class] equals:[type class]];
    [self assert:6.66 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "0.00", "datatype": "http://www.w3.org/2001/XMLSchema#double" });
    [self assert:[SPLiteralDouble class] equals:[type class]];
    [self assert:0 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "0", "datatype": "http://www.w3.org/2001/XMLSchema#double" });
    [self assert:[SPLiteralDouble class] equals:[type class]];
    [self assert:0 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "-0.00", "datatype": "http://www.w3.org/2001/XMLSchema#double" });
    [self assert:[SPLiteralDouble class] equals:[type class]];
    [self assert:0 equals:[type value]];
}

- (void)testInteger
{
    var type;

    type = SPGetType({ "type": "typed-literal", "value": "0", "datatype": "http://www.w3.org/2001/XMLSchema#integer" });
    [self assert:[SPLiteralInteger class] equals:[type class]];
    [self assert:0 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "12345", "datatype": "http://www.w3.org/2001/XMLSchema#integer" });
    [self assert:[SPLiteralInteger class] equals:[type class]];
    [self assert:12345 equals:[type value]];

    type = SPGetType({ "type": "typed-literal", "value": "-66", "datatype": "http://www.w3.org/2001/XMLSchema#integer" });
    [self assert:[SPLiteralInteger class] equals:[type class]];
    [self assert:-66 equals:[type value]];
}

- (void)testBadJSON
{
    [self assertThrows:function() { SPGetType({ "foo": "typed-literal" }) }];
    [self assertThrows:function() { SPGetType({}) }];
}


@end
