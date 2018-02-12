<#
.Synopsis
   This script updates the AzureAD license
.EXAMPLE
   Set-APAzureADUserLicense -ObjectId 'guid' -AssignedLicenses $license
   This command will perform the license changes in the $licese Microsoft.Open.AzureAD.Model.AssignedLicenses object.
   Any licenses not in the $license object will not be effected.
#>
function Set-APAzureADUserLicense
{
    [CmdletBinding()]
    [OutputType([void])]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({$_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'})]
        [String]$ObjectId,

        [Parameter(Mandatory=$true,
                   Position=1)]
        [Microsoft.Open.AzureAD.Model.AssignedLicenses]$AssignedLicenses
    )

    Begin
    {
    }
    Process
    {
        Try { 
            Set-AzureADUserLicense -ObjectId $ObjectId -AssignedLicenses $AssignedLicenses
        }
        Catch {
            Throw "Failed to set license: $_"
        }
    }
    End
    {
        
    }
}
