# Add ADFS Relying Party Trust for Silent Circle

# These will become parameters of the script

$clientId = 'SCEntClient'
$rpid = 'silentcircle-entapi://rpid'
$rpName = 'Silent Circle Enterprise Client'
$redirectURIs = @(
    'https://accounts.silentcircle.com/sso/oauth2/return/',
    'https://accounts-dev.silentcircle.com/sso/oauth2/return/',
    'https://localsc.ch/sso/oauth2/return/',
    'http://localsc.ch:8000/sso/oauth2/return/'
)
# TODO: Allow entry of group name and look up corresponding group SID.
# Change this to the appropriate group SID for the enterprise
$groupSID = 'S-1-5-21-207668378-2981979776-1947477811-1112'

$issuanceTransformRules = @"
@RuleName = "Silent Circle Enterprise Client Mapping"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
   Issuer == "AD AUTHORITY"]
   => issue(store = "Active Directory",
      types = ("sub", "email", "name"),
      query = ";objectGUID,userPrincipalName,displayName;{0}",
      param = c.Value);
"@

$issuanceAuthorizationRules = @"
@RuleTemplate = "Authorization"
@RuleName = "Silent Circle Enterprise User"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
   Value =~ "^(?i)$groupSID$"]
   => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",
            Value = "PermitUsersWithClaim");
"@

# Remove-AdfsRelyingPartyTrust -TargetName $rpName

if (Get-AdfsRelyingPartyTrust $rpName) {
    Write-Warning "Relying Party trust already exists: $rpName; skipping creation."
} else {
    Add-AdfsRelyingPartyTrust `
        -Identifier $rpid `
        -Name $rpName `
        -IssuanceTransformRules $issuanceTransformRules `
        -IssuanceAuthorizationRules $issuanceAuthorizationRules `
        -IssueOAuthRefreshTokensTo AllDevices `
        -AlwaysRequireAuthentication
}


# Remove-AdfsClient -TargetClientId $clientId

if (Get-AdfsClient -ClientId $clientId) {
    Write-Warning "Client ID already exists: $clientId; skipping creation."
} else {
    Add-AdfsClient `
        -ClientId $clientId `
        -Name $rpName `
        -Description $rpName `
        -RedirectURI $redirectURIs
}
