component 
	output = false
	hint = "I help resolve resources into variables and events."
	{

	// I return an initialized object.
	public any function init( 
		string defaultParamName = "event",
		boolean matchEntireResource = true
		) {

		// Store the default param name - this is the name given to the param that gets
		// passed in as a string when resource routes are being defined.
		variables.defaultParamName = defaultParamName;

		// Check to see if we should be matching against the entire resource. If FALSE,
		// this will allow a resource pattern to match a substring of a resource.
		variables.matchEntireResource = matchEntireResource;

		// Store the list of resource patterns that can be matched.
		resourceConfigurations = [];

		// Define the RegularExpression pattern used to match the dynamic parameters in 
		// the URI. By default, we'll look for a pattern like, ":id". However, we want
		// to allow users to provide an optional pattern to restrict the matching of the
		// the pattern, ":id(\d+)".
		// --
		// :( [/(]+ )
		// (?: ( \( [^)]+ \) ) )?
		// --
		// In this case, the first matched group is the param-name. The second matched 
		// group is the optional pattern to be used.
		uriComponentPattern = createObject( "java", "java.util.regex.Pattern" ).compile(
			javaCast( "string", ":([^/(]+)(?:(\([^)]+\)))?" )
		);

		// If the user does not provide an explicit replacement pattern, we'll use the 
		// following patternw which matches everything up until the next "/".
		defaultParamPattern = "([^/]+)";

		// Return this object reference.
		return( this );

	}


	// ----
	// PUBLIC METHODS.
	// ----


	// I define a resource that can be accessed with the DELETE HTTP method. The 
	// resourceParams can be null, string, or struct. If a string is passed-in, it is
	// given the default param name.
	public any function delete(
		required string resourceUri, 
		any resourceParams = structNew()
		) {

		buildResourceConfiguration( "DELETE", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the GET HTTP method. The 
	// resourceParams can be null, string, or struct. If a string is passed-in, it is 
	// given the default param name.
	public any function get(
		string resourceUri, 
		any resourceParams = structNew()
		) {

		buildResourceConfiguration( "GET", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the POST HTTP method. The
	// resourceParams can be null, string, or struct. If a string is passed-in, it is
	// given the default param name.
	public any function post(
		required string resourceUri, 
		any resourceParams = structNew()
		) {

		buildResourceConfiguration( "POST", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the PUT HTTP method. The 
	// resourceParams can be null, string, or struct. If a string is passed-in, it is
	// given the default param name.
	public any function put(
		required string resourceUri, 
		any resourceParams = structNew()
		) {

		buildResourceConfiguration( "PUT", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I resolve the given resource and HTTP action. If the given resource URI cannot
	// be resolved, I return NULL.
	public any function resolveResource(
		string httpMethod = "GET",
		string resourceUri
		) {

		// Loop over the resource congifurations, looking for a match on both the HTTP
		// method and the pattern. 
		for ( var resourceConfiguration in resourceConfigurations ) {

			// Check the HTTP method first since it will fail faster. If the HTTP method 
			// matched, reset the pattern mathcer for the current resource.
			if ( resourceConfiguration.httpMethod == httpMethod ) {

				// Create a matcher for the current resource Uri - this can be used to 
				// both test the pattern as well as extract captured groups.
				var matcher = resourceConfiguration.compiledResource.pattern.matcher(
					javaCast( "string", resourceUri )
				);

				// Now, check to see if the pattern matches.
				if ( matcher.find() ) {

					// The pattern matched! Create the base result.
					var resolution = {
						httpMethod = httpMethod,
						resourceUri = resourceUri,
						resourceParams = duplicate( resourceConfiguration.resourceParams )
					};

					// Now, add on the resource params mapped in the actual resource 
					// value. To make this easier, get some short-hand reference to our 
					// compiled values.
					var groupNames = resourceConfiguration.compiledResource.groupNames;
					var groupCount = resourceConfiguration.compiledResource.groupCount;

					// For each captured group, define one resource param. Based on our
					// pattern, we know that all captrued groups will be defined.
					for ( var groupIndex = 1 ; groupIndex <= groupCount ; groupIndex++ ) {

						var groupName = groupNames[ groupIndex ];
						var groupValue = matcher.group( javaCast( "int", groupIndex ) );

						resolution.resourceParams[ groupName ] = groupvalue;

					}

					return( resolution );

				}

			}

		}

		// If we made it this far, none of the compiled resources matched the incoming
		// resource URI. Return NULL.
		return;

	}


	// I provide an alternate resource map definition in which the resource can be 
	// defined first.
	public any function when(
		required string resourceUri,
		required struct httpMethods
		) {

		var supportedHttpMethods = [ "get", "put", "post", "delete" ];

		// Loop over each type of HTTP method to see if this resource allows for it.
		for ( var httpMethod in supportedHttpMethods ) {

			if ( structKeyExists( httpMethods, httpMethod ) ) {

				// Pass this through to the individual httpMethod-based configuration
				// method.
				evaluate( "#httpMethod#( resourceUri, httpMethods[ httpMethod ] )" );

			}

		}

		// Return this object reference for method chaining.
		return( this );

	}


	// ----
	// PRIVATE METHODS.
	// ----


	// I build the resource configuration for the given HTTP method and resource. This
	// configuration will be cached.
	private void function buildResourceConfiguration(
		required string httpMethod,
		required string resourceUri,
		required any resourceParams
		) {

		// If the params is a string, convert to a struct.
		if ( isSimpleValue( resourceParams ) ) {

			// Store a temporary value so that we can overwrite the param without 
			// losing it.
			var paramValue = resourceParams;

			// Use the default param name when adding this param as an item in the params 
			// collection.
			resourceParams = {
				"#defaultParamName#" = paramValue
			};

		}

		// Compile the resource.
		var compiledResource = compileResourcePattern( resourceUri );

		// Create a new resource configuration.
		var resourceConfiguration = {
			httpMethod = httpMethod,
			compiledResource = compiledResource,
			resourceParams = resourceParams
		};

		// Store the new configuration.
		arrayAppend( resourceConfigurations, resourceConfiguration );

	}


	// I take the user-provided Resource URI and compile it down into a Java regular 
	// expression pattern matcher that can be reused.
	private any function compileResourcePattern( required string resourceUri ) {

		// Each resource can map resource components to named parameters. Each component
		// will be converted to a captruing group which we'll have to map via indicie.
		var groupNames = [];

		// Get the matcher for the given URI.
		var matcher = uriComponentPattern.matcher( javaCast( "string", resourceUri ) );

		// Create a string buffer to hold the resultant URI pattern as we start replacing
		// named parameters with regular expression patterns.
		var buffer = createObject( "java", "java.lang.StringBuffer" ).init();

		// Find all dynamic parameters in the resource definition.
		while ( matcher.find() ) {

			var paramName = matcher.group( javaCast( "int", 1 ) );
			var paramPattern = matcher.group( javaCast( "int", 2 ) );

			// If the user did not provide an explicit replacement pattern, then use the
			// default replacement pattern which gets the entire uri component.
			if ( isNull( paramPattern ) ) {

				paramPattern = defaultParamPattern;

			}

			// Store the component name.
			arrayAppend( groupNames, paramName );

			// Replace with the regex pattern.
			matcher.appendReplacement(
				buffer,
				matcher.quoteReplacement( javaCast( "string", paramPattern ) )
			);

		}

		// Add any trailing part of the resource URI that has no dynamic elements.
		matcher.appendTail( buffer );

		// Make sure the resultant pattern will start matching at the start of the input.
		var resourcePattern = ( "\A" & buffer.toString() );

		// If the resource mapper is intended to match the entire string, the append the 
		// end-of-string matcher.
		if ( matchEntireResource ) {

			resourcePattern &= "\Z";

		}

		// Create our compiled resource. Each compiled resource has a Java Pattern object
		// and the collection of group names.
		var compiledResource = {
			groupNames = groupNames,
			groupCount = arrayLen( groupNames ),
			pattern = createObject( "java", "java.util.regex.Pattern" ).compile(
				javaCast( "string", resourcePattern )
			),
			rawDefinition = resourceUri
		};

		return( compiledResource );

	}

}