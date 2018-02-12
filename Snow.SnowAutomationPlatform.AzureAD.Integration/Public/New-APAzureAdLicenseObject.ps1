<#
.Synopsis
   This helper function creates a new AssignedLicense object.
.DESCRIPTION
   This helper function creates a new AssignedLicense object.
   Using one or more of these objects we can create a object of type AssignedLicenses (Notice the 'S').
   The AssignedLicenses object can then be connected to a AzureADUser.
.EXAMPLE
   New-APAzureAdLicenseObject -SkuId <guid-1> -DisabledPlans <guid-2>
   This will create a AssignedLicense object with SkuId guid-1,
   and exclude the applicationplan guid-2
#>
function New-APAzureAdLicenseObject
{
    [CmdletBinding()]
    [OutputType([Microsoft.Open.AzureAD.Model.AssignedLicense])]
    Param
    (
        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'})]        
        [String]$SkuId,

        [Parameter(Mandatory=$false)]
        [ValidateScript({$_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'})]        
        [String[]]$DisabledPlans
    )

    Begin
    {
        if ($DisabledPlans -and -not $SkuId) {
            Throw 'Can´t disable plans without license.'
        }

        Try { 
            $License = New-Object -TypeName  Microsoft.Open.AzureAD.Model.AssignedLicense
        }
        Catch {
            Throw "Failed to create license object: $_"
        }
    }
    Process
    {
        If ($SkuId) {
            $License.SkuId = $SkuId
        }
        If ($DisabledPlans) {
            $License.DisabledPlans = $DisabledPlans
        }
    }
    End
    {
        Write-Verbose 'Successfully created Azure license object.'
        $License
    }
}
