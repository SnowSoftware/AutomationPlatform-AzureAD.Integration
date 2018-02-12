<#
.Synopsis
   Gets Azure AD User
.DESCRIPTION
   Wrapper around Get-AzureADUser to simplify integration to Snow Automation Platorm.
.EXAMPLE
   Get-APAzureADUser
   This command will return all Azure AD Users
.EXAMPLE
   Get-APAzureADUser -SearchString 'User'
   This command will return all Azure AD Users with DisplayName starting with 'User'.
   This command does not support wildcards.
.EXAMPLE
   Get-APAzureADUser -ObjectId <ObjectGuid>
   This command will return Azure AD User with ObjectId Matching searchstring.
   This command does not support wildcards.
.EXAMPLE
   Get-APAzureADUser -Filter "DisplayName eq 'User'"
   This command will return all Azure AD Users where DisplayName is exactly 'User'.
   Filter is written in common OData query language.
   This command does support wildcards.
#>
function Get-APAzureADUser
{
    [CmdLetBinding(DefaultParameterSetName='All')]
    [OutputType([Microsoft.Open.AzureAD.Model.User])]
    Param
    (
        [Parameter(Mandatory=$true, 
            ParameterSetName='SearchString')]
        [String]$SearchString,

        [Parameter(Mandatory=$true, 
            ParameterSetName='ObjectId')]
        [ValidateScript({$_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'})]
        [String]$ObjectId,

        [Parameter(Mandatory=$true, 
            ParameterSetName='Filter')]
        [String]$Filter,

        [Parameter(Mandatory=$False, 
            Position=0,
            ParameterSetName='SearchString')]
        [Parameter(Mandatory=$False, 
            Position=0,
            ParameterSetName='ObjectId')]
        [Parameter(Mandatory=$False, 
            Position=0,
            ParameterSetName='Filter')]
        [Parameter(Mandatory=$False, 
            Position=0,
            ParameterSetName='All')]
        [Switch]$All
    )
    Begin
    {
        $SearchFilter = @{}

        switch ($PSCmdlet.ParameterSetName)
            {
                'SearchString' { $SearchFilter.SearchString = $SearchString }
                'ObjectId'     { $SearchFilter.ObjectId = $ObjectId }
                'Filter'       { $SearchFilter.Filter = $Filter }
            }
        If ($All) {
            $SearchFilter.All = $True
        }

    }
    Process
    {
        try { 
            Get-AzureADUser @SearchFilter
        }
        Catch {
            Write-Error "Failed to Get Azure AD User: $($_.Exception.Message)"
        }
    }
    End
    {
    }
}
