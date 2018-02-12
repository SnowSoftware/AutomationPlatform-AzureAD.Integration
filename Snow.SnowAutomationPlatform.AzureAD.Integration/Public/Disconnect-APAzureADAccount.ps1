<#
.Synopsis
   Disconnects all active AzureAD connections
.EXAMPLE
   Disconnect-APAzureADAccount
#>
function Disconnect-APAzureADAccount
{
    [CmdletBinding()]
    Param
    (
        
    )

    Begin
    {
    }
    Process
    {
        Try {
            $Null = Disconnect-AzureAD
            $count = Get-AzureADTenantDetail -All $true
        }
        catch {
            # Empty catch blocks are considered worst practice,
            # but since Get-AzureADTenantDetail always fails when no connection is found
            # we use this as a workaround
        }
    }
    End
    {
        If ($count) {
            Write-Error 'Failed to disconnect Azure sessions'
        }
        Else {
            Write-Output 'Disconnected all active Azure sessions'
        }
    }
}
