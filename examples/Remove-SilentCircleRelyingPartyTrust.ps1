###############################################
# Remove Silent Circle ADFS Relying Party Trust
###############################################

<#
.SYNOPSIS
Removes a Silent Circle Relying Party Trust and OAuth 2.0 Client to AD FS.

.DESCRIPTION

The Remove-SilentCircleRelyingPartyTrust cmdlet removes a Silent Circle Relying
Party Trust from Active Directory Federation Services for the Silent Circle
enterprise client.

This cmdlet also removes the OAuth 2.0 ADFS client that defines how Silent
Circle applications communicate with AD FS using the OAuth 2.0 protocol.

.EXAMPLE

PS C:\Administrator\Scripts> .\Remove-SilentCircleRelyingPartyTrust.ps1

This command removes the relying party trust and OAuth 2.0 client using the
default parameter values.

.EXAMPLE

PS C:\Administrator\Scripts> .\Remove-SilentCircleRelyingPartyTrust.ps1 -RelyingPartyName 'Silent Circle Enterprise Client' -Verbose

This command removes the relying party trust named 'Silent Circle Enterprise
Client' and the OAuth 2.0 client named by the default paramater -ClientId,
displaying Verbose-level information.

.EXAMPLE

PS C:\Administrator\Scripts> .\Remove-SilentCircleRelyingPartyTrust.ps1 -RelyingPartyName 'Silent Circle Enterprise Client' -ClientId SCEntClient -Verbose

This command removes the relying party trust named 'Silent Circle Enterprise
Client'  and the OAuth 2.0 client named SCEntClient, displaying Verbose-level
information.

#>

[CmdletBinding()]
Param(
    # Specifies a client identifier for the OAuth 2.0 client to remove.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId = 'SCEntClient',

    # Specifies the friendly name of this relying party trust.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    [alias("RPN")]
    $RelyingPartyName = 'Silent Circle Enterprise Client'
)


### Begin Block ###

Begin {
    Set-StrictMode -Version Latest

    function checkIfAdmin {
        $currentPrincipal = [Security.Principal.WindowsIdentity]::GetCurrent()
        $obj = New-Object Security.Principal.WindowsPrincipal($currentPrincipal)
        $obj.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    function removeRPTrust($Name) {
        try {
            Remove-AdfsRelyingPartyTrust -TargetName $Name
            Write-Output "Removed AdfsRelyingPartyTrust -TargetName $Name"
        } catch [ArgumentException] {
            Write-Warning "Relying Party Trust friendly name not found: '$Name'"
        }

    }

    function removeAdfsClient($ClientId) {
        try {
            Remove-AdfsClient -TargetClientId $ClientId
            Write-Output "Removed AdfsClient -TargetClientId $ClientId"
        } catch [ArgumentException] {
            Write-Warning "Adfs Client ID not found: '$ClientId'"
        }
    }

} # Begin


### Process Block ###

Process {
    if (checkIfAdmin) {
        removeRPTrust $RelyingPartyName
        removeAdfsClient $ClientId
    } else {
        Write-Error "This PowerShell cmdlet requires Administrator privilege. " +
                    "Try executing using right click -> 'Run as Administrator'"
    }

} # Process


### End Block ###

End {}


# vim: ts=4 sts=4 sw=4 et si filetype=ps1 syntax=ps1

