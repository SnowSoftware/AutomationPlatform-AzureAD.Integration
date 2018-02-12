<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Get-APAzureADUserLicense
{
    [CmdletBinding()]
    [OutputType([Microsoft.Open.AzureAD.Model.LicenseDetail])]
    Param
    (
        [Parameter(Mandatory=$true,
                   Position=0)]
        [ValidateScript({$_ -match '^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$'})]
        [String]$ObjectId
    )

    Begin
    {

    }
    Process
    {
        Try { 
            Get-AzureADUserLicenseDetail -ObjectId $ObjectId
        }
        Catch {
            Write-Error "Failed to get License for ObjectId $($ObjectId): $($_.Exception.Message)"
        }
    }
    End
    {
        
    }
}
