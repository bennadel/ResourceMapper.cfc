<cfscript>

component
	extends = "mxunit.framework.TestCase"
	output = "false"
	hint = "I test the resource mapper against various resource URIs."
	{


	function testHttpMethods(){

		// Create an instance of our resource mapper. In this case, we are going to allow
		// the full resource to be mapped (ie. not allowing any partial resource matches).
		var mapper = new lib.ResourceMapper(
			defaultParamName = "action"
		);

		// Define our resources.
		mapper
			.get(
				"/blog/:blogID",
				"blog.view"
			)
			.delete(
				"/blog/:blogID",
				"blog.delete"
			)
			.put(
				"/blog/:blogID",
				"blog.update"
			)
			.get(
				"/blog/:blogID/comments",
				"blog.viewComments"
			)
			.post(
				"/blog/:blogID/comments",
				"blog.addComment"
			)
		;


		// Test things that we know will work.

		var resolution = mapper.resolveResource( "GET", "/blog/123" );

		assertEquals( "blog.view", resolution.resourceParams.action, "GET failed" );


		var resolution = mapper.resolveResource( "DELETE", "/blog/123" );

		assertEquals( "blog.delete", resolution.resourceParams.action, "DELETE failed" );


		var resolution = mapper.resolveResource( "PUT", "/blog/123" );

		assertEquals( "blog.update", resolution.resourceParams.action, "PUT failed" );


		var resolution = mapper.resolveResource( "GET", "/blog/123/comments" );

		assertEquals( "blog.viewComments", resolution.resourceParams.action, "GET failed" );


		var resolution = mapper.resolveResource( "POST", "/blog/123/comments" );

		assertEquals( "blog.addComment", resolution.resourceParams.action, "POST failed" );

	}


	function testWhenMethod(){

		// Create an instance of our resource mapper. In this case, we are going to allow
		// the full resource to be mapped (ie. not allowing any partial resource matches).
		var mapper = new lib.ResourceMapper(
			defaultParamName = "action"
		);

		// Define our resources.
		mapper
			.when(
				"/blog/:blogID",
				{
					get = "blog.view",
					delete = "blog.delete",
					put = "blog.update"

				}
			)
			.when(
				"/blog/:blogID/comments",
				{
					get = "blog.viewComments",
					post = "blog.addComment"

				}
			)
		;


		// Test things that we know will work.

		var resolution = mapper.resolveResource( "GET", "/blog/123" );

		assertEquals( "blog.view", resolution.resourceParams.action, "GET failed" );


		var resolution = mapper.resolveResource( "DELETE", "/blog/123" );

		assertEquals( "blog.delete", resolution.resourceParams.action, "DELETE failed" );


		var resolution = mapper.resolveResource( "PUT", "/blog/123" );

		assertEquals( "blog.update", resolution.resourceParams.action, "PUT failed" );


		var resolution = mapper.resolveResource( "GET", "/blog/123/comments" );

		assertEquals( "blog.viewComments", resolution.resourceParams.action, "GET failed" );


		var resolution = mapper.resolveResource( "POST", "/blog/123/comments" );

		assertEquals( "blog.addComment", resolution.resourceParams.action, "POST failed" );

	}


	function testFailures(){

		// Create an instance of our resource mapper. In this case, we are going to allow
		// the full resource to be mapped (ie. not allowing any partial resource matches).
		var mapper = new lib.ResourceMapper(
			defaultParamName = "action"
		);

		// Define our resources.
		mapper
			.get(
				"/blog/:blogID",
				"blog.view"
			)
			.post(
				"/blog/:blogID/comments",
				"blog.addComment"
			)
		;


		// Test things that we know will NOT work.

		var resolution = mapper.resolveResource( "POST", "/blog/123" );

		assertEquals( 
			"undefined", 
			( isNull( resolution.resourceParams.action ) ? "undefined" : "" ), 
			"Mismatch failed"
		);


		var resolution = mapper.resolveResource( "GET", "/blog/123/comments" );

		assertEquals( 
			"undefined", 
			( isNull( resolution.resourceParams.action ) ? "undefined" : "" ), 
			"Mismatch failed"
		);

	}


	function testFullResourceMatch(){

		// Create an instance of our resource mapper. This time, we are going make sure
		// that we don't get false matches due to smaller resources.
		var mapper = new lib.ResourceMapper();

		// Define our resources. Define the longest ones first to see if we will 
		// accidentally match them (they are matched in the same order in which they are
		// defined).
		mapper
			.get(
				"/blog/:blogID",
				"blog.view"
			)
			.get(
				"/blog/:blogID/comments",
				"blog.getComments"
			)
		;


		// Test things that we know will work.

		var resolution = mapper.resolveResource( "GET", "/blog/123/comments" );

		assertEquals( "blog.getComments", resolution.resourceParams.event, "Full match failed" );

	}


	function testPartialResourceMatch(){

		// Create an instance of our resource mapper. This time, we are going to allow for
		// partial matches to see if we do get a false match.
		var mapper = new lib.ResourceMapper(
			defaultParamName = "action",
			matchEntireResource = false
		);

		// Define our resources. Define the longest ones first to see if we will 
		// accidentally match them (they are matched in the same order in which they are
		// defined).
		mapper
			.get(
				"/blog/:blogID",
				"blog.view"
			)
			.get(
				"/blog/:blogID/comments",
				"blog.getComments"
			)
		;


		// Test things that we know will work.

		var resolution = mapper.resolveResource( "GET", "/blog/123/comments" );

		assertEquals( "blog.view", resolution.resourceParams.action, "Partial match failed" );

	}


}

</cfscript>