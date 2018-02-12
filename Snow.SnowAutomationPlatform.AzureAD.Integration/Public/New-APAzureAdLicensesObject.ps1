<#
.Synopsis
   This helper function creates a new AssignedLicenses object.
.DESCRIPTION
   This helper function creates a new AssignedLicenses object.
   The AssignedLicenses object contains one or more objects of type AssignedLicense,
   And is used to add, remove, or update a AzureADUser license
.EXAMPLE
   
#>
function New-APAzureAdLicensesObject
{
    [CmdletBinding()]
    [OutputType([Microsoft.Open.AzureAD.Model.AssignedLicenses])]
    Param
    (
        [Parameter(Mandatory=$false)]
        [Microsoft.Open.AzureAD.Model.AssignedLicense[]]$AddLicenses,
        
        [Parameter(Mandatory=$false)]
        [String[]]$RemoveLicenses
    )

    Begin
    {
        Try { 
            $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
        }
        catch {
            Throw "Failed to create AssignedLicenses object: $_"
        }
    }
    Process
    {
        If ($AddLicenses) {
            $licenses.AddLicenses = $AddLicenses
        }
        If ($RemoveLicenses) {
            $licenses.RemoveLicenses = $RemoveLicenses
        }
    }
    End
    {
        $licenses
    }
}
