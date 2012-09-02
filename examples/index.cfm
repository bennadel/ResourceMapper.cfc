<cfscript>


	// Param the HTTP method to test with.
	param
		name = "url.httpMethod"
		type = "string"
		default = "GET"
	;

	// Param the resource uri.
	param 
		name = "url.resourceUri" 
		type = "string" 
		default = ""
	;


	// Create an instance of our resource mapper. When we instantiate it,
	// we can define a default param name. This is the name of the param 
	// that is created if we pass-in a string as our resource params 
	// argument when defining routes. 
	resourceMapper = new lib.ResourceMapper( defaultParamName = "event" );


	// Let's define our resources / routes. When defining resources,
	// can use both the individual HTTP method methods (ie. get, put, 
	// post, delet). Or, we can use a then when() method and define 
	// the HTTP verbs as properties.
	resourceMapper
		.when(
			"/blog/:blogID/comments",
			{
				get = "blog.getComments",
				post = "blog.addComment"
			}
		)
		.get(
			"/blog/archive/:year/:month",
			{
				event = "blog.search",
				archive = true
			}
		)
		.get(
			"/blog/:blogID", 
			"blog.view"
		)
		.get(
			"/blog", 
			"blog.list"
		)
		.post(
			"/blog",
			"blog.add"
		)
	;


	// Check to see if a resource has been defined.
	if ( len( url.resourceUri ) ) {

		resourceResolution = resourceMapper.resolveResource(
			httpMethod = url.httpMethod,
			resourceUri = url.resourceUri
		);

	}


	// Define some resources to demo.
	demoResources = [
		"/blog",
		"/blog/123",
		"/blog/archive/2012/08",
		"/blog/123/comments"
	];


</cfscript>

<!--- Reset the output buffer. --->
<cfcontent type="text/html" />

<cfoutput>

	<!doctype html>
	<html>
	<head>
		<meta charset="utf-8" />

		<title>ResourceMapper.cfc</title>
	</head>
	<body>

		<h1>
			ResourceMapper.cfc
		</h1>

		<ul>

			<!--- Output each demo resource using GET and POST. --->
			<cfloop 
				index="demoResource" 
				array="#demoResources#">

				<li>
					<a href="#cgi.script_name#?httpMethod=GET&resourceUri=#urlEncodedFormat( demoResource )#">GET #demoResource#</a>
				</li>
				<li>
					<a href="#cgi.script_name#?httpMethod=POST&resourceUri=#urlEncodedFormat( demoResource )#">POST #demoResource#</a>
				</li>

			</cfloop>

		</ul>


		<!--- Check to see if we have a resolution. --->
		<cfif len( url.resourceUri )>

			<h2>
				Resource Resolution
			</h2>

			<cfif isNull( resourceResolution )>

				<p>
					Sorry, the resource could not be found.
				</p>

			<cfelse>

				<cfdump
					var="#resourceResolution#" 
					label="Resource Resolution" 
					/>

			</cfif>

		</cfif>

	</body>
	</html>

</cfoutput>