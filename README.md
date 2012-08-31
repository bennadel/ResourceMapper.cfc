
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
resource definition has a higher precendence than the second resource 
defintion. As such, the most specific resources should be defined first, 
followed by the more general resource definitions.

Under the hood, each Resource URI is compiled down into a Java Pattern and a
Java Matcher object. This makes resolving the incoming resource (and extracting
the named parameters) an extremely fast process.


[1]: http://www.bennadel.com