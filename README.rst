Sparkles Framework - SPARQL for Cappuccino!
===========================================

:Author:
    Martin Galpin
:Contact:
    m@66laps.com

Sparkles is a SPARQL [SPARQL]_ object-RDF mapper written in
Objective-J for Cappuccino.

The framework is currently in the early stages of development. The
API is currently subject (and very likely) to change. It currently
includes a bare minimum of features. Similarly, this documentation is
not an exhaustive resource but it should provide a basic understanding
of the framework.

Introduction
------------

Sparkles makes writing semantic web applications in Cappuccino
easier. It does this by reducing boilerplate code, providing
dynamic access to RDF resources and consuming SPARQL endpoints over
HTTP.

This is not an attempt to build a fully featured RDF
environment. There are numerous limitations that complicate the
building of libraries for web applications (local file access,
multi-threading, cross-domain requests et al.) For more specialised
use-cases, consider using the `SuRF`_ library for Python or
`ActiveRDF`_ for Ruby. If, however, you just want to build smarter
Cappuccino apps, fast, read on!

Features
--------

Classes and Collections
.......................

Sparkles provides three core classes: ``SPEndPoint`` (a connection to
a SPARQL endpoint), ``SPClass`` (a representation of an RDF type) and
``SPInstance`` (a resource that is of an RDF type). For instance,
consider the following example::

    var endPoint = [SPEndPoint endPointWithString:@"http://dbpedia.org/sparql"],
        classAthlete = [endPoint classForName:@"dbo:Athlete"];

The variable ``classAthlete`` now represents the RDF type
``<http://dbpedia.org/ontology/Athlete>``. Additionally, because it was
created using ``classForName:`` it has automatically been associated
with the current endpoint.

It is now possible to retrieve a collection of instances for this
class. Currently, the only method to do this is ``all`` . This
initialises a collection containing all resources of this class and
returns an instance of ``SPCollectionResult``.

``SPCollectionResult`` is a `lazy collection`_ of resources. This
means that the actual execution of SPARQL does not happen until is
necessary. It is triggered by registering an observer with the
collection.

Sparkles communicates asynchronously with the SPARQL endpoint. To do
this, Sparkles uses an asynchronous ``CPURLConnection`` and notifies
observers that an object is ready by posting a notification to
``CPNotificationCenter``.

For example, continuing with the previous example, we can initialise
our collection of resources as follows::

    ... AppController.j

    _allAthletes = [classAthlete all];
    [_allAthletes addObserver:self selector:@selector(athletesDidLoad:)];

    ...

    - (void)athletesDidLoad:(CPNotification)aNotification
    {
        // print all "dbo:Athlete"
        CPLog([_allAthletes all]);

	// print the first "dbo:Athlete"
	CPLog([_allAthletes first]);
    }

By default, initialising a collection only retrieves the URI of each
resource. However, there are times when retrieving more than just a
URI is helpful - for example, when displaying the collection as a
list. Executing an individual request for the properties of each instance
would be very inefficient.

``SPCollectionResult`` can *preload* a small number of properties when
initialising a collection. Let's modify the previous example to take
advantage of this::

    ... AppController.j

    _allAthletes = [classAthlete all];
    [_allAthletes setPreloadedProperties:@"foaf:name", @"dbo:birthPlace"]; // preload
    [_allAthletes addObserver:self selector:@selector(athletesDidLoad:)];

    ...

    - (void)athletesDidLoad:(CPNotification)aNotification
    {
	// print the first "dbo:Athlete"
	var enumerator = [[_allAthletes all] objectEnumerator],
	    athlete;

	while(athelete = [enumerator nextObject])
	{
	    CPLog(@"%@ was born in %@",
	        [athlete property:@"foaf:name"],
	        [athlete property:@"dbo:birthPlace"]);
	}
    }

However, do not abuse ``setPreloadedProperties:`` - it is provided
only as a pragmatic concession to efficiency. It is very easy to
exceed the soft limit of an end point if the cartesian product of a
resource is excessive.

Instances
.........

Individual resources are represented by instances of
``SPInstance``. Like ``SPCollectionResult``, this class features
*lazy* initialisation of properties and the same asynchronous
observer-notification model.

Properties can be accessed by specifying the property URI to
``property:``. For more information on how types are represented, see
`Literal Types`_.

When the cardinality of a property is greater than one, it is
automatically replaced by a ``CPArray``. If this happens, each element
of the array is an individual property value.

We can continue with the previous example of *athletes* and retrieve
more information about a resource::

     _selectedAthlete = [_allAthletes first];
     [_selectedAthlete addObserver:self selector:@selector(athleteDidLoad:)];

     ....
     - (void)athletesDidLoad:(CPNotification)aNotification
     {
         CPLog(@"Name: %@ (Given Name: %@)",
	    [_selectedAthlete property:@"dbpprop:fullname"],
	    [_selectedAthlete property:@"foaf:givenName"]);

         CPLog(@"Description: %@",
	    [_selectedAthlete property:@"dbpprop:shortDescription");

         CPLog(@"Homepage: %@",
	    [_selectedAthlete property:@"foaf:page");
     }

Automatic Namespaces
....................

Sparkles includes automatic expansion of qualified namespaces (or
QNames). Any parameter that requires a URI may be given in the
shorthand form. For example, when requesting a property of a class,
you might write::

    var foafPerson = [store classForName:@"foaf:Person"];
    ...
    var person = [[foafPerson all] first];
    [person property:@"foaf:name"];

The QName ``foaf:name`` is automatically expanded to
``http://xmlns.com/foaf/0.1/name``.

Sparkles includes a comprehensive list of namespaces by default (see
``SPDefaultNamespaces.j``). Additional namespaces can be registered at
runtime. Custom namespaces have priority over their default
counterparts, meaning default namespaces can be overridden. For
example::

    [[SPNamespaceManager sharedManager] addNamespace:@"http://example.org/ns#" forPrefix:@"ex"];
    ...
    var alerts = [store classForName:@"ex:Alert"];

Note that ``SPNamespaceManager`` is a `singleton instance`_. This is a
pragmatic decision to simplify its use throughout the framework.

.. _`Literal Types`:

Literal Types
.............

Sparkles supports URI references, literals (with optional language
tags) and typed-literals. These are deserialised into
``SPLiteralURI``, ``SPPlainLiteral`` and ``SPTypedLiteral`` instances
respectively. Subclasses of ``SPTypedLiteral`` can be created to
provide easy access to native datatypes (where possible).

Sparkles will automatically convert typed-literals to a corresponding
subclass of ``SPTypedLiteral`` according to the associations declared
in ``_SPTypedLiteralClasses`` (see ``SPTypes.j``). It is possible to
register new custom types at runtime (or override existing types) using the
function ``SPRegisterTypedLiteral()``.

Sparkles currently includes support for most primitive datatypes
declared in the `XML Schema`_ [XSDT]_.

For example, given the following `RDF graph`_::

    @prefix dt:   <http://example.org/datatype#> .
    @prefix ns:   <http://example.org/ns#> .
    @prefix :     <http://example.org/ns#> .
    @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .

    :x   ns:p     "cat"@en .
    :y   ns:a     "42"^^xsd:integer .
    :y   ns:b     "true"^^xsd:boolean .
    :z   ns:s     "abc"^^dt:specialDatatype .

These properties might be accessed using the following::

    var instance = ...

    var p = [instance property:@"ns:p"];
    // [p class] == [SPPlainLiteral class]
    // [p value] == "cat"
    // [p language] == "en"

    var a = [instance property:@"ns:a"];
    // [a class] == [SPLiteralInteger class]
    // [a value] == 42

    var b = [instance property:@"ns:n"];
    // [b class] == [SPLiteralBoolean class]
    // [b value] == YES

    var s = [instance property:@"ns:s"];
    // [s class] == [SPTypedLiteral class]
    // [s value] == "abc"
    // [s datatype] == "http://example.org/datatype#specialDatatype"

You might notice that the property ``ns:s`` was deserialised as an
instance of ``SPTypedLiteral``. This is because, by default, Sparkles
does not include a more specialised association for this datatype. We
can create our own subclass of ``SPTypedLiteral`` and register it with
Sparkles at runtime::

   @implementation MySpecialDataType : SPTypedLiteral

   - (id)value
   {
	return convertToSomething(_value); // the literal value is stored in _value
   }

   @end

   ... AppController.j

   SPRegisterTypedLiteral(@"ns:specialDatatype", MySpecialDataType);

Now, any literal with the datatype ``ns:specialDatatype`` will be
automatically deserialised as an instance of ``MySpecialDataType``.

Query Builder
.............

``SPQueryBuilder`` provides a mechanism for programatically creating
SPARQL queries. It supports the ``SELECT``, ``CONSTRUCT``, ``ASK`` and
``DESCRIBE`` query forms and all graph patterns, dataset clauses,
solution and sequence modifiers.

Utility functions are provided to generate common SPARQL
constructs. These include ``SPTriple()``, ``SPGraph()``, ``SPOptional()``,
``SPNamed()``, ``SPFilter()`` and ``SPUnion()``. Most functions are
`variadic`_. It is suggested that the utilities functions are used
rather than manually creating the corresponding class instances. For
example, given the following SPARQL query::

    PREFIX foaf: <http://xmlns.com/foaf/0.1/>
    PREFIX dc:   <http://purl.org/dc/elements/1.1/>

    SELECT ?name ?mbox ?date
    WHERE
    {
        ?g dc:publisher ?name ;
        dc:date ?date .
        GRAPH ?g
        { ?person foaf:name ?name ; foaf:mbox ?mbox }
    }

It could be reproduced programatically as follows::

    var builder = [SPQueryBuilder select:@"?name", @"?mbox", @"?date"];

    [builder where:SPTriple(@"?g", @"dc:publisher", @"?name"),
                   SPTriple(@"g", @"dc:date", @"?date"),
		   SPNamed(@"?g", SPTriple(@"?person", @"foaf:name", @"?name"),
                                  SPTriple(@"?person", @"foaf:mbox", @"?mbox"))];

    // builder [builder description] == SPARQL query as a string

Note that there is no need to explicitly declare the common namespaces. In
this example, the appropriate `FOAF`_ and `Dublin Core`_ namespaces are
automatically inserted at the beginning of the
query. ``SPQueryBuilder`` will also respect any custom namespaces
registered with ``SPNamespaceManager``.


Installing Sparkles
...................

Clone the repository and place it within your applications
``Frameworks`` directory. You can then start using Sparkles
immediately::

   @import <Sparkles/Sparkles.j>

Test Suite
..........

To run the test suite::

   $ jake test

Roadmap
.......

* Optional synchronous requests
* Simple inference engine
    * Automatic detection of property cardinality, equivalence, domain
      and range
* Support for saving and updating resources
* Basic authentication
* Caching of objects (HTML5 local storage)
* Lazy collection initialisation

License
-------

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation; either version 3 of the
License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
02110-1301 USA

References
----------

.. [XSDT] XML Schema Part 2: Datatypes Second Edition, P. V. Biron, A. Malhotra, Editors, W3C Recommendation, 28 October 2004, http://www.w3.org/TR/2004/REC-xmlschema-2-20041028/ . Latest version available at http://www.w3.org/TR/xmlschema-2/ .
.. [SPARQL] SPARQL Query Language for RDF, E. Prud'hommeaux, A. Seaborne, W3C Recommendation, 15 January 2008, http://www.w3.org/TR/2008/REC-rdf-sparql-query-20080115/ . Latest version available at http://www.w3.org/TR/rdf-sparql-query/ .

.. _singleton instance: http://en.wikipedia.org/wiki/Singleton_pattern
.. _XML Schema: http://www.w3.org/TR/xmlschema-2/
.. _RDF Graph: http://www.w3.org/TR/rdf-sparql-query/#matchingRDFLiterals
.. _lazy collection: http://en.wikipedia.org/wiki/Lazy_initialization
.. _variadic: http://en.wikipedia.org/wiki/Variadic_function
.. _FOAF: http://www.foaf-project.org/
.. _Dublin Core: http://dublincore.org/
.. _SuRF: http://code.google.com/p/surfrdf/
.. _CPActiveRecord: https://github.com/nciagra/Cappuccino-Extensions
.. _ActiveRDF: http://activerdf.org/
