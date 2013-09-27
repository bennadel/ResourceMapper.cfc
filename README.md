
# ResourceMapper.cfc

by Ben Nadel ([www.bennadel.com][1])

The ResourceMapper.cfc ColdFusion component maps HTTP methods and Resource 
URIs to an arbitrary set of configured parameters. This can be used when 
translating SES (Search Engine Safe) URLs into event variables that your 
underlying application can use.

There are four main methods for mapping a resource to a particular HTTP method:

* get( resourceUri, resourceParams )
* put( resourceUri, resourceParams )
* post( resourceUri, resourceParams )
* delete( resourceUri, resourceParams )

There is an alternate method, when(), that allows the resource to be defined
first, followed by the HTTP methods:

* when( resourceUri, httpMethods )

In this case, the "httpMethods" argument is a struct that maps HTTP verbs to 
resource params:

httpMethods :: struct :

* get = resourceParams
* put = resourceParams
* post = resourceParams
* delete = resourceParams

Resource URIs can contain variables in the form of ":name". For example, the
following Resource URI:

/blog/:blogID/comments

... will resolve the URL:

/blog/123/comments

... and extract the ":blogID" as a named-parameter with the value, "123".

When a resource is resolved, it is checked against the configured resources
in the same order in which they have been defined. This means that first 
resource definition has a higher precedence than the second resource 
definition. As such, the most specific resources should be defined first, 
followed by the more general resource definitions.

Under the hood, each Resource URI is compiled down into a Java Pattern and a
Java Matcher object. This makes resolving the incoming resource (and extracting
the named parameters) an extremely fast process.

## Using Explicit Regular Expression Pattern Matching

By default, the ResourceMapper.cfc will replace instances of the named-
parameters with the regular expression pattern:

([^/]+)

This says, "match anything up until the next instance of '/'." If your 
resources are more complicated than that, you can specify an explicit pattern
to use when matching the URI component:

/foo/:id(YOUR_PATTERN)

After the :name portion, you can supply your own regular expression pattern 
inside of a set of parenthesis. For obvious reasons, your pattern cannot, 
itself, contain parenthesis or the ResourceMapper.cfc will not be able to 
parse the URL.

In the following example, I want to ensure that the :id parameter is numeric:

/blog/:id(\d+)/comments

Notice that I am supplying an explicit pattern, "\d+". 

This feature provides the added benefit that you can now match partial URI 
components since the explicit pattern breaks you out of the default "/" 
component delimiter. For example, you can extract a numeric ID that is at
the start of a URI component:

/blog/:id(\d+)-my-blog-title.htm

The ResourceMapper.cfc will extract the numeric :id even though it does not
match the entire URI component.

[1]: http://www.bennadel.com