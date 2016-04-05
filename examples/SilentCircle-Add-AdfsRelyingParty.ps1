################################################
# Add ADFS Relying Party Trust for Silent Circle
################################################

<#
.SYNOPSIS
Add Silent Circle Relying Party Trust.
#>

Param(
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId = 'SCEntClient',

    [ValidateNotNullOrEmpty()]
    [String]
    [alias("RPID")]
    $RelyingPartyId = 'silentcircle-entapi://rpid',

    [ValidateNotNullOrEmpty()]
    [String]
    [alias("RPN")]
    $RelyingPartyName = 'Silent Circle Enterprise Client',

    [ValidateNotNullOrEmpty()]
    [String[]]
    [alias("RURIs")]
    $RedirectURIs = @(
        'https://accounts.silentcircle.com/sso/oauth2/return/',
        'https://accounts-dev.silentcircle.com/sso/oauth2/return/',
        'https://localsc.ch/sso/oauth2/return/',
        'http://localsc.ch:8000/sso/oauth2/return/'
    ),

    [String]
    [alias("IAG")]
    $IssuanceAuthorizationGroupName,

    [Switch]
    $Verbose = $false
)

Set-StrictMode -Version 3

function getSIDForUserOrGroup {
    param (
        [String]$Id
    )

    $objUser = New-Object System.Security.Principal.NTAccount($Id)
    $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
    $strSID.Value
}

if ($IssuanceAuthorizationGroupName) {
    $groupSID = (getSIDForUserOrGroup $IssuanceAuthorizationGroupName)
    Write-Debug "groupSID for '$IssuanceAuthorizationGroupName': '$groupSID'"

    $issuanceAuthorizationRules = @"
@RuleTemplate = "Authorization"
@RuleName = "Silent Circle Enterprise User"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
    Value =~ "^(?i)$groupSID$"]
    => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",
            Value = "PermitUsersWithClaim");
"@
}

$issuanceTransformRules = @"
@RuleName = "Silent Circle Enterprise Client Mapping"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
   Issuer == "AD AUTHORITY"]
   => issue(store = "Active Directory",
      types = ("sub", "email", "name"),
      query = ";objectGUID,userPrincipalName,displayName;{0}",
      param = c.Value);
"@

# Remove-AdfsRelyingPartyTrust -TargetName $RelyingPartyName

if (-not (Get-AdfsRelyingPartyTrust $RelyingPartyName)) {
    if ($IssuanceAuthorizationGroupName) {
        Add-AdfsRelyingPartyTrust `
            -Identifier $RelyingPartyId `
            -Name $RelyingPartyName `
            -IssuanceTransformRules $issuanceTransformRules `
            -IssuanceAuthorizationRules $issuanceAuthorizationRules `
            -IssueOAuthRefreshTokensTo AllDevices `
            -AlwaysRequireAuthentication
    } else {
    Add-AdfsRelyingPartyTrust `
        -Identifier $RelyingPartyId `
        -Name $RelyingPartyName `
        -IssuanceTransformRules $issuanceTransformRules `
        -IssueOAuthRefreshTokensTo AllDevices `
        -AlwaysRequireAuthentication
    }
    if ($Verbose) {
        Write-Output "Created Relying Party Trust:"
        Get-AdfsRelyingPartyTrust $RelyingPartyName
    }
} else {
    Write-Warning "Relying Party trust already exists: $RelyingPartyName; skipping creation."
}


# Remove-AdfsClient -TargetClientId $ClientId

if (-not (Get-AdfsClient -ClientId $ClientId)) {
    Add-AdfsClient `
        -ClientId $ClientId `
        -Name $RelyingPartyName `
        -Description $RelyingPartyName `
        -RedirectURI $RedirectURIs
    if ($Verbose) {
        Write-Output "Created ADFS Client:"
        Get-AdfsClient -ClientId $ClientId
    }
} else {
    Write-Warning "Client ID already exists: $ClientId; skipping creation."
}
