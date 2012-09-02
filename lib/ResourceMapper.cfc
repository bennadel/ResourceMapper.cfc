<cfscript>

component 
	output = "false"
	hint = "I help resolve resources into variables and events."
	{


	// I return an initialized object.
	function init ( 
		String defaultParamName = "event",
		Boolean matchEntireResource = true
		) {

		// Store the default param name - this is the name given to 
		// the param that gets passed in as a string when resource
		// routes are being defined.
		variables.defaultParamName = defaultParamName;

		// Check to see if we should be matching against the entire
		// resource. If FALSE, this will allow a resource pattern to
		// match a substring of a resource.
		variables.matchEntireResource = matchEntireResource;

		// Store the list of resource patterns that can be matched.
		variables.resourceConfigurations = []; 

		// Return this object reference.
		return( this );

	}


	// ----
	// PUBLIC METHODS.
	// ----


	// I define a resource that can be accessed with the DELETE HTTP 
	// method. The resourceParams can be null, string, or struct. If
	// a string is passed-in, it is given the default param name.
	function delete (
		String resourceUri, 
		Any resourceParams = structNew()
		) {

		this._buildResourceConfiguration ( "DELETE", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the GET HTTP 
	// method. The resourceParams can be null, string, or struct. If
	// a string is passed-in, it is given the default param name.
	function get (
		String resourceUri, 
		Any resourceParams = structNew()
		) {

		this._buildResourceConfiguration ( "GET", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the POST HTTP 
	// method. The resourceParams can be null, string, or struct. If
	// a string is passed-in, it is given the default param name.
	function post (
		String resourceUri, 
		Any resourceParams = structNew()
		) {

		this._buildResourceConfiguration ( "POST", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I define a resource that can be accessed with the PUT HTTP 
	// method. The resourceParams can be null, string, or struct. If
	// a string is passed-in, it is given the default param name.
	function put (
		String resourceUri, 
		Any resourceParams = structNew()
		) {

		this._buildResourceConfiguration ( "PUT", resourceUri, resourceParams );

		// Return this object reference for method chaining.
		return( this );

	}


	// I resolve the given resource and HTTP action. If the given 
	// resource URI cannot be resolved, I return NULL.
	function resolveResource (
		String httpMethod = "GET",
		String resourceUri
		) {

		// Loop over the resource congifurations, looking for a match
		// on both the HTTP method and the pattern. 
		for ( var resourceConfiguration in variables.resourceConfigurations ) {

			// Check the HTTP method first since it will fail faster.
			// If the HTTP method matched, reset the pattern mathcer
			// for the current resource.
			if (
				( resourceConfiguration.httpMethod == httpMethod ) &&
				( resourceConfiguration.matcher.reset( javaCast( "string", resourceUri ) ).find() )
				) {

				// The pattern matched! Create the base result.
				var resolution = {
					httpMethod = httpMethod,
					resourceUri = resourceUri,
					resourceParams = duplicate( resourceConfiguration.resourceParams )
				};

				// Now, add on the resource params mapped in the 
				// actual resource value. To make this easier, get 
				// some short-hand reference to our compiled values.
				var groupNames = resourceConfiguration.compiledResource.groupNames;
				var groupCount = resourceConfiguration.compiledResource.groupCount;

				// For each captured group, define one resource param.
				// Based on our pattern, we know that all captrued 
				// groups will be defined.
				for ( var groupIndex = 1 ; groupIndex <= groupCount ; groupIndex++ ) {

					var groupName = groupNames[ groupIndex ];
					var groupValue = resourceConfiguration.matcher.group( javaCast( "int", groupIndex ) );

					resolution.resourceParams[ groupName ] = groupvalue;

				}

				return( resolution );

			}

		}

		// If we made it this far, none of the compiled resources
		// matched the incoming resource URI. Return NULL.
		return;

	}


	// I provide an alternate resource map definition in which the
	// resource can be defined first.
	function when (
		String resourceUri,
		Struct httpMethods
		) {

		var supportedHttpMethods = [ "get", "put", "post", "delete" ];

		// Loop over each type of HTTP method to see if this resource
		// allows for it.
		for ( var httpMethod in supportedHttpMethods ) {

			if ( structKeyExists( httpMethods, httpMethod ) ) {

				// Pass this through to the individual 
				// httpMethod-based configuration method.
				evaluate( "this.#httpMethod#( resourceUri, httpMethods[ httpMethod ] )" );

			}

		}

		// Return this object reference for method chaining.
		return( this );

	}


	// ----
	// PRIVATE METHODS.
	// ----


	// I build the resource configuration for the given HTTP method 
	// and resource. This configuration will be cached.
	function _buildResourceConfiguration (
		String httpMethod,
		String resourceUri,
		Any resourceParams
		) {

		// If the params is a string, convert to a struct.
		if ( isSimpleValue( resourceParams ) ) {

			// Store a temporary value so that we can overwrite the 
			// param without losing it.
			var paramValue = resourceParams;

			// Use the default param name when adding this param as
			// an item in the params collection.
			resourceParams = {
				"#variables.defaultParamName#" = paramValue
			};

		}

		// Compile the resource.
		var compiledResource = this._compileResourcePattern ( resourceUri );

		// Create a new resource configuration. We're going to tack 
		// on a Matcher instance as well; this way, we can easily 
		// reset the matcher later when doing searches.
		var resourceConfiguration = {
			httpMethod = httpMethod,
			compiledResource = compiledResource,
			resourceParams = resourceParams,
			matcher = compiledResource.pattern.matcher( javaCast( "string", "" ) )
		};

		// Store the new configuration.
		arrayAppend(
			variables.resourceConfigurations,
			resourceConfiguration
		);

	}


	// I take the user-provided Resource URI and compile it down into
	// a Java regular expression pattern matcher that can be reused.
	function _compileResourcePattern ( String resourceUri ) {

		// Each resource can map resource components to named 
		// parameters. Each component will be converted to a captruing
		// group which we'll have to map via indicie.
		var groupNames = [];

		// Extract the resource components.
		var resourceParams = reMatch( ":[^/]+", resourceUri );

		// Before we start replacing components with capturing groups,
		// let's create our base pattern. We'll start by making sure
		// the resource maps to the beginning of the string.
		var resourcePattern = ("^" & resourceUri);

		// Check to see if we are matching the entire resource.
		if ( variables.matchEntireResource ) {

			// By appending the end-of-string character, we will 
			// prevent partial resource matching.
			resourcePattern &= "$";

		}

		// Now, let's replace each group.
		for ( var resourceParam in resourceParams ) {

			// Store the component name (everything after the ":").
			arrayAppend(
				groupNames,
				listLast( resourceParam, ":" )
			);

			// Replace the component with a capturing group.
			resourcePattern = replace( 
				resourcePattern,
				resourceParam,
				"([^/]+)",
				"one"
			);

		}

		// Create our compiled resource. Each compiled resource has a
		// Java Pattern object and the collection of group names.
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

</cfscript>