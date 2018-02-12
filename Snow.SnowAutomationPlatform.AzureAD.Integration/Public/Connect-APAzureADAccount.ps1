<#
.Synopsis
   This function connects user to Azure AD
.EXAMPLE
   Connect-APAzureADAccount -Credential (Get-Credential)
#>
function Connect-APAzureADAccount
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [pscredential]$Credential
    )

    Begin
    {
    }
    Process
    {
        Try {
            $Connection = Connect-AzureAD -Credential $Credential -ErrorAction Stop
        }
        Catch {
            Write-error "Failed to login: $($_.Exception.Message)"
            Throw "Failed to login: $($_.Exception.Message)"
        }

    }
    End
    {
        Write-Output 'Successfully connected to AzureAD'
        $Connection
    }
}

