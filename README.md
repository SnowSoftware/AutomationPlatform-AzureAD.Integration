# Snow.SnowAutomationPlatform.AzureAD.Integration

This module is for use in Snow Automation Platform with AzureAD functions.
It contains wrappers to make Azure API calls easier to handle within Automation Platform.
Examples of workflows using this module include, but are not limited to:
  * Office365 Licensing

## Prereqs

  * AzureAD module from Microsoft - Install using the powershell gallery.
    
## Contributing

### Issues
If you find a problem with this module, please file an issue using the GitHib Issue tracker using the following guidelines:

  * File a single issue per problem and feature request.

  * The more information you can provide, the more likely someone will be successful reproducing the issue and finding a fix.

  * Please include reproducion steps with each issue, including expected result, and what you actually get.

  * If possible, Simplify your code around the issue so we can better isolate the problem.

Please remember, before you report an Issue,
Search the issue repository to see if there exists a duplicate.

If you find a problem with Snow Automation Platform, or any related Services, workflows, Activities, or other AP specific processes,
Please contact support@snowsoftware.com

### Development
If you would like to add or change something in this code, you are free to fork and do a pull request with your requested changes using the following guidelines:

  * Always follow powershell best practice guidelines found [on github.com/PoshCode](https://github.com/PoshCode/PowerShellPracticeAndStyle)

  * Always include Pester tests for your changes
  
  * Never use shorthand, Alias or other, non standard, terminology in your scripts.

  * If any external dependencies or specific powershell versions are required, theese must be stated i #requires block.

  * Scripts should be well documented.

  * All scripts should support Powershell version 3.0 if nothing else is clearly stated inside the script.

When reporting an issue or doing a pull request, you must always follow our [Code of Conduct](code-of-conduct.md).
