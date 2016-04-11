############################################
# Add Silent Circle ADFS Relying Party Trust
############################################

<#
.SYNOPSIS
Adds a Silent Circle Relying Party Trust and OAuth 2.0 Client to AD FS.

.DESCRIPTION

The Add-SilentCircleRelyingPartyTrust cmdlet adds a Relying Party Trust to
Active Directory Federation Services for the Silent Circle enterprise client.
This trust enables Silent Circle enterprise users to use Single Sign-On to
authenticate themselves as authorized users of Silent Circle. This applies to
Silent Circle applications such as Silent Phone, and the Silent Circle Accounts
Web site.

This cmdlet also adds an OAuth 2.0 ADFS client that defines how Silent Circle
applications communicate with AD FS using the OAuth 2.0 protocol.

.NOTES

1. Defining an authorized group (-IssuanceAuthorizationGroupName)

You may optionally provide an Active Directory group name to control which
users are authorized to use Silent Circle. The group name must already exist
and be known to the AD FS system on which this cmdlet is executed. If the group
name is not found, the cmdlet will fail with an error. It is your
responsibility to assign users to this group.  Users that are not members of
this group will be denied authorization to use Silent Circle.

2. Existing trust or client

If a Relying Party Trust already exists with the same name (-RelyingPartyName)
or IDs (-RelyingPartyIds), this cmdlet displays a warning message and does not
create or change the Relying Party trust.

If an OAuth 2.0 client exists with the same ID (-ClientId), this cmdlet
displays a warning message
and does not create or change the OAuth 2.0 client details.

3. Recreating the trust and client from scratch

If there is an existing relying party trust and/or client and you want to
override them, specify -DeleteBeforeCreating. This cmdlet will delete any
existing Relying Party Trust and OAuth 2.0 Client details before attempting to
create them.

.EXAMPLE

PS C:\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1

This command adds the relying party trust using the default parameter values,
and does not add any Issuance Authorization Rules.

.EXAMPLE

PS C:\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User' -Verbose

This command adds the relying party trust using the default parameter values,
and adds Issuance Authorization Rules that allow only members of the 'Silent
Circle Enterprise User' group to be authorized for Silent Circle, displaying
Verbose information.

.EXAMPLE

PS C:\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User' -DeleteBeforeCreating -Verbose

This command first checks if there is an existing relying party trust and OAuth
2.0 client, and deletes them if found.

Thereafter it adds the relying party trust using the default parameter values,
and adds Issuance Authorization Rules that allow only members of the 'Silent
Circle Enterprise User' group to be authorized for Silent Circle, showing
Verbose information.
#>

[CmdletBinding()]
Param(
    # Specifies a client identifier for the OAuth 2.0 client to register with
    # AD FS.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    $ClientId = 'SCEntClient',

    # Specifies the unique identifiers for this relying party trust.  No other
    # trust can use an identifier from this list. Uniform Resource Identifiers
    # (URIs) are often used as unique identifiers for a relying party trust,
    # but you can use any string of characters.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [alias("RPID")]
    [String[]]
    $RelyingPartyIds = @('silentcircle-entapi://rpid'),

    # Specifies the friendly name of this relying party trust.  This value is
    # also used as the name and description of the OAuth 2.0 client that this
    # cmdlet creates.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [String]
    [alias("RPN")]
    $RelyingPartyName = 'Silent Circle Enterprise Client',

    # Specifies one or more redirection URIs for the OAuth 2.0 client to
    # register with AD FS. The OAuth 2.0 client specifies the redirection URI
    # when it requests authorization to access a resource secured by AD FS. You
    # can register more than one redirection URI for a single client
    # identifier. The redirect URI must be a valid URI.
    [parameter()]
    [ValidateNotNullOrEmpty()]
    [String[]]
    [alias("RURIs")]
    $RedirectURIs = @(
        'https://accounts.silentcircle.com/sso/oauth2/return/',
        'https://accounts-dev.silentcircle.com/sso/oauth2/return/',
        'https://localsc.ch/sso/oauth2/return/',
        'http://localsc.ch:8000/sso/oauth2/return/'
    ),

    # Specifies the Issuance Authorization Group Name, which must correspond to
    # an existing Active Directory group.  Omitting this parameter will cause
    # no Issuance Authorization rules to be added.  If the group does not exist
    # in Active Directory, an error will occur and no Issuance Authorization
    # Rules will be added.
    [parameter()]
    [alias("IAG")]
    [String]
    $IssuanceAuthorizationGroupName,

    # Indicates whether the Relying Party and Client data should be deleted
    # before they are created, if they exist.
    [parameter()]
    [Switch]
    $DeleteBeforeCreating = $false
)


### Begin Block ###

Begin {
    Set-StrictMode -Version Latest

    function checkIfAdmin {
        $currentPrincipal = [Security.Principal.WindowsIdentity]::GetCurrent()
        $obj = New-Object Security.Principal.WindowsPrincipal($currentPrincipal)
        $obj.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    # Returns the SID for the given user or group name.
    function getSidForUserOrGroup($Id) {
        $objUser = New-Object System.Security.Principal.NTAccount($Id)
        try {
            $objUser.Translate([System.Security.Principal.SecurityIdentifier]).Value
        }
        catch [System.Security.Principal.IdentityNotMappedException] {
            throw "Cannot find user or group with name '$Id', aborting."
        }
    }


    # Checks if the AD FS trust specified by is absent and returns $true if it is.
    # If -DeleteIfPresent is specified, deletes the trust and returns $true.
    # Otherwise, returns $false.
    function ensureAdfsRelyingPartyTrustIsAbsent($Name, $DeleteIfPresent) {
        $isPresent = Get-AdfsRelyingPartyTrust -Name $Name
        if ($isPresent -and $DeleteIfPresent) {
            Remove-AdfsRelyingPartyTrust -TargetName $Name
            Write-Verbose "Removed AdfsRelyingPartyTrust -TargetName '$Name'"
            $isPresent = $false
        }

        -not $isPresent
    }


    # Checks if client specified by -ClientId is absent and returns $true if it is.
    # If -DeleteIfPresent is specified, deletes any matching client and returns
    # $true.
    function ensureAdfsClientIsAbsent($ClientId, $DeleteIfPresent) {
        $isPresent = Get-AdfsClient -ClientId $ClientId
        if ($isPresent -and $DeleteIfPresent) {
            Remove-AdfsClient -TargetClientId $ClientId
            Write-Verbose "Removed AdfsClient -ClientId '$ClientId'"
            $isPresent = $false
        }

        -not $isPresent
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
} # Begin


### Process Block ###

Process {
    if (!(checkIfAdmin)) {
        Write-Error "This PowerShell cmdlet requires Administrator privilege. " +
                    "Try executing using right click -> 'Run as Administrator'"
        return
    }

    # Get SID for group, if specified. Fail if SID not found.
    $issuanceAuthorizationRules = $null
    if ($IssuanceAuthorizationGroupName) {
        $groupSID = getSidForUserOrGroup $IssuanceAuthorizationGroupName
        Write-Verbose "Group SID for '$IssuanceAuthorizationGroupName': '$groupSID'"

        $issuanceAuthorizationRules = @"
@RuleTemplate = "Authorization"
@RuleName = "Silent Circle Enterprise User"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
   Value =~ "^(?i)$groupSID$"]
=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",
         Value = "PermitUsersWithClaim");
"@
    }

    # Create Relying Party Trust
    if (ensureAdfsRelyingPartyTrustIsAbsent $RelyingPartyName $DeleteBeforeCreating) {
        Add-AdfsRelyingPartyTrust `
            -Identifier $RelyingPartyIds `
            -Name $RelyingPartyName `
            -IssueOAuthRefreshTokensTo AllDevices `
            -AlwaysRequireAuthentication
        Write-Verbose "Added AdfsRelyingPartyTrust -Name $RelyingPartyName"

        if ($issuanceAuthorizationRules) {
            Set-AdfsRelyingPartyTrust `
                -TargetName $RelyingPartyName `
                -IssuanceAuthorizationRules $issuanceAuthorizationRules
            Write-Verbose "Set IssuanceAuthorizationRules '$RelyingPartyName': `n$issuanceAuthorizationRules"
        }

        if ($issuanceTransformRules) {
            Set-AdfsRelyingPartyTrust `
                -TargetName $RelyingPartyName `
                -IssuanceTransformRules $issuanceTransformRules
            Write-Verbose "Set IssuanceTransformRules '$RelyingPartyName': `n$issuanceTransformRules"
        }

        Write-Verbose "Created Relying Party Trust:$( (Get-AdfsRelyingPartyTrust $RelyingPartyName | Out-String) )"
    } else {
        Write-Warning "Relying Party trust already exists: $RelyingPartyName; skipping creation."
    }


    # Create OAuth 2.0 client
    if (ensureAdfsClientIsAbsent $ClientId $DeleteBeforeCreating) {
        Add-AdfsClient `
            -ClientId $ClientId `
            -Name $RelyingPartyName `
            -Description $RelyingPartyName `
            -RedirectURI $RedirectURIs
        Write-Verbose "Created AdfsClient:$( (Get-AdfsClient -ClientId $ClientId | Out-String) )"
    } else {
        Write-Warning "Client ID already exists: $ClientId; skipping creation."
    }

} # Process


### End Block ###

End {}


# vim: ts=4 sts=4 sw=4 et si filetype=ps1 syntax=ps1

