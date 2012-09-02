<cfscript>

component 
	output = "false"
	hint = "I define the applications settings and event handlers."
	{


	// Define the application settings.
	this.name = hash( getCurrentTemplatePath() );
	this.applicationTimeout = createTimeSpan( 0, 0, 5, 0 );
	this.sessionManagement = false;

	// Get the current directory and the root directory.
	this.appDirectory = getDirectoryFromPath( getCurrentTemplatePath() );
	this.projectDirectory = (this.appDirectory & "../");

	// Map the LIB directory so we can create our components.
	this.mappings[ "/lib" ] = (this.projectDirectory & "lib");


}

</cfscript>