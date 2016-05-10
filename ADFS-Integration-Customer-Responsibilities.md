# ADFS Integration for Silent Circle Enterprise Customers

## Introduction

This document details how to integrate Silent Circle with your
federated identity management system, in this case Active Directory
Federation Services, so your users can be authenticated, and
authorized to use Silent Circle, via their Single Sign-on
credentials.

We recommend first doing an integration between Silent Circle's test
systems and your test systems, if at all possible.  Once this is
done, the next step would be to repeat the integration between
Silent Circle's production systems and your production systems.

The integration procedure on your end consists of the steps below.

* A [configuration procedure](#sccp), which configures the trust
  relationship between Silent Circle and your AD FS infrastructure;
* An [acceptance test procedure](#scatp), in which you run through
  a set of acceptance tests to ensure that the integration is
  successful.

Please see the SSO Customer Integration Overview for a higher-level
view of the integration procedure.

## System requirements

Silent Circle supports Active Directory Federation Services (ADFS),
qualified as follows.

* Windows Server 2012 R2 operating system.
* [ADFS 3.0][], using [OAuth 2.0][RFC6749] Authorization Code Flow.
* Claim Rule Configuration such that
    * ADFS issues OAuth Refresh Tokens to all devices, along with
      the Access Tokens.
    * ADFS must always require authentication (so as not to allow
      existing SSO credentials to be used).
    * The above claim rule requirements can be met by using
      [Silent Circle AD FS Issuance Transform Rules](#sscafitr).
    * We support optional issuance authentication rules. An example
      of these rules may be found in
      [Silent Circle AD FS Issuance Authentication Rules](#sscafiar).
* Silent Circle Relying Party Client Configuration ([Appendix C](#sscafrpis))

<a name="sccp"></a>

## Configuration Procedure

### Configure Active Directory Federation Services (ADFS)

This is where you add the Silent Circle trust relationship. There are two ways
of doing this:

* [Configure using Windows PowerShell cmdlets](#scups) provided by Silent Circle.
* [Configure using the AD FS GUI tools](#scutg).

The GUI tools show you step-by-step what is happening, while the cmdlet is much
quicker and easier to use for people that have access to, and experience with,
Windows PowerShell.

<a name="scups"></a>

### Configure using PowerShell cmdlets

PowerShell cmdlets to assist with integration are available for download.
Please download and install them as described in [Appendix C](#sscafrpis).

#### Cmdlet Help Documentation

The cmdlets have detailed on-line help documentation that can be seen by
running the following commands in the same directory as the cmdlets:

```ps1
Get-Help .\Add-SilentCircleRelyingPartyTrust.ps1 -Full
Get-Help .\Remove-SilentCircleRelyingPartyTrust.ps1 -Full
```

### Add Silent Circle as a Relying Party

First decide if you want to use an Active Directory group to restrict which
users may use Silent Circle, using an Issuance Authorization Rule that the
cmdlet will create for you. If you do decide to go ahead, ensure you know the
group name and that it is visible on your system. For example, let's say the
group is named 'Silent Circle Enterprise User'. Using `Get-ADGroup`, you can
find out if the group is known.

```ps1
> Get-ADGroup -Identity 'Silent Circle Enterprise User'


DistinguishedName : CN=Silent Circle Enterprise User,CN=Users,DC=sso-dev0,DC=silentcircle-inc,DC=org
GroupCategory     : Security
GroupScope        : Global
Name              : Silent Circle Enterprise User
ObjectClass       : group
ObjectGUID        : af259a14-9f85-437e-a9c2-e327b03129fb
SamAccountName    : Silent Circle Enterprise User
SID               : S-1-5-21-207668378-2981979776-1947477811-1112
```

In this example, we'll assume you have added the abovenamed group and want to
create an Issuance Authorization Rule. Here's the command and sample output.

```ps1
PS C:\Users\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User'
PS C:\Users\Administrator\Scripts>
```

If you want to see what was created, and you don't want to run the cmdlet
again, you can do it like this:

```ps1
PS C:\Users\Administrator\Scripts> Get-AdfsRelyingPartyTrust -Name 'Silent Circle Enterprise Client'
... output omitted ...

PS C:\Users\Administrator\Scripts> Get-AdfsClient -ClientId SCEntClient
... output omitted ...
```

If you run the command a second time, you get warning messages telling you that
the Relying Party trust and OAuth 2.0 client exist, and the cmdlet will not
take any action:

```ps1
PS C:\Users\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User'
WARNING: Relying Party trust already exists: Silent Circle Enterprise Client; skipping creation.
WARNING: Client ID already exists: SCEntClient; skipping creation.
```

If you're not happy with the results, you can tell the command to first clear
out the trust and client before running:

```ps1
PS C:\Users\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User' -DeleteBeforeCreating
PS C:\Users\Administrator\Scripts>
```

Finally, if you want to remove all traces of the integration, you can use the
`Remove-SilentCircleRelyingPartyTrust.ps1` cmdlet:

```ps1
PS C:\Users\Administrator\Scripts> .\Remove-SilentCircleRelyingPartyTrust.ps1
Removed AdfsRelyingPartyTrust -TargetName Silent Circle Enterprise Client
Removed AdfsClient -TargetClientId SCEntClient

```

If you want more detail on what's going on behind the scenes, you can add the
`-Verbose` option, as follows (notice we've used the `-DeleteBeforeCreating`
option too:

```ps1
PS C:\Users\Administrator\Scripts> .\Add-SilentCircleRelyingPartyTrust.ps1 -IssuanceAuthorizationGroupName 'Silent Circle Enterprise User' -Verbose -DeleteBeforeCreating
VERBOSE: Group SID for 'Silent Circle Enterprise User': 'S-1-5-21-207668378-2981979776-1947477811-1112'
VERBOSE: Removed AdfsRelyingPartyTrust -TargetName 'Silent Circle Enterprise Client'
VERBOSE: Added AdfsRelyingPartyTrust -Name Silent Circle Enterprise Client
VERBOSE: Set IssuanceAuthorizationRules 'Silent Circle Enterprise Client':
@RuleTemplate = "Authorization"
@RuleName = "Silent Circle Enterprise User"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
   Value =~ "^(?i)S-1-5-21-207668378-2981979776-1947477811-1112$"]
=> issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",
         Value = "PermitUsersWithClaim");
VERBOSE: Set IssuanceTransformRules 'Silent Circle Enterprise Client':
@RuleName = "Silent Circle Enterprise Client Mapping"
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
   Issuer == "AD AUTHORITY"]
=> issue(store = "Active Directory",
         types = ("sub", "email", "name"),
         query = ";objectGUID,userPrincipalName,displayName;{0}",
         param = c.Value);
VERBOSE: Created Relying Party Trust:

AllowedAuthenticationClassReferences : {}
AutoUpdateEnabled                    : False
DelegationAuthorizationRules         :
EncryptionCertificateRevocationCheck : CheckChainExcludeRoot
PublishedThroughProxy                : False
IssuanceAuthorizationRules           : @RuleTemplate = "Authorization"
                                       @RuleName = "Silent Circle Enterprise User"
                                       c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value =~ "^(?i)S-1-5-21-207668378-2981979776-1947477811-1112$"]
                                        => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "PermitUsersWithClaim");


SigningCertificateRevocationCheck    : CheckChainExcludeRoot
WSFedEndpoint                        :
AdditionalWSFedEndpoint              : {}
ClaimsProviderName                   : {}
IssuanceTransformRules               : @RuleName = "Silent Circle Enterprise Client Mapping"
                                       c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname", Issuer == "AD AUTHORITY"]
                                        => issue(store = "Active Directory", types = ("sub", "email", "name"), query = ";objectGUID,userPrincipalName,displayName;{0}", param = c.Value);


ClaimsAccepted                       : {}
ConflictWithPublishedPolicy          : False
EncryptClaims                        : True
Enabled                              : True
EncryptionCertificate                :
Identifier                           : {silentcircle-entapi://rpid}
LastMonitoredTime                    : 1/1/1900 12:00:00 AM
LastPublishedPolicyCheckSuccessful   :
LastUpdateTime                       : 1/1/1900 12:00:00 AM
MetadataUrl                          :
MonitoringEnabled                    : False
Name                                 : Silent Circle Enterprise Client
NotBeforeSkew                        : 0
EnableJWT                            : False
AlwaysRequireAuthentication          : False
Notes                                :
OrganizationInfo                     :
ImpersonationAuthorizationRules      :
AdditionalAuthenticationRules        :
ProxyEndpointMappings                : {}
ProxyTrustedEndpoints                : {}
ProtocolProfile                      : WsFed-SAML
RequestSigningCertificate            : {}
EncryptedNameIdRequired              : False
SignedSamlRequestsRequired           : False
SamlEndpoints                        : {}
SamlResponseSignature                : AssertionOnly
SignatureAlgorithm                   : http://www.w3.org/2001/04/xmldsig-more#rsa-sha256
TokenLifetime                        : 0
AllowedClientTypes                   : Public
IssueOAuthRefreshTokensTo            : AllDevices




VERBOSE: Removed AdfsClient -ClientId 'SCEntClient'
VERBOSE: Created AdfsClient:

RedirectUri : {http://localsc.ch:8000/sso/oauth2/return/, https://accounts.silentcircle.com/sso/oauth2/return/, https://accounts-dev.silentcircle.com/sso/oauth2/return/, https://localsc.ch/sso/oauth2/return/}
Name        : Silent Circle Enterprise Client
Description : Silent Circle Enterprise Client
ClientId    : SCEntClient
BuiltIn     : False
Enabled     : True
ClientType  : Public
```

<a name="scutg"></a>

### Configure using the AD FS GUI Tools

#### In Server Manager, select `Tools > AD FS Management`.

![AD FS Management](images/adfs_001.png  "AD FS Management")

#### Launch the `Add Relying Party Trust` Wizard

![Launch Add Relying Party Trust Wizard](images/adfs_002.png  "Launch Add Relying Party Trust Wizard")

#### Start the `Add Relying Party Trust` Wizard

![Start Add Relying Party Trust Wizard](images/adfs_003.png  "Start Add Relying Party Trust Wizard")

#### Select `Enter data about the relying party manually`

![Enter data about the relying party manually](images/adfs_004.png  "Enter data about the relying party manually")

#### Add Silent Circle information

* Enter "Silent Circle Enterprise Client" in `Display name`, and any notes that
  might be of interest.
* Click `Next`.

![Add Silent Circle information](images/adfs_005.png  "Add Silent Circle information")

#### Select AD FS Profile

![Select AD FS Profile](images/adfs_006.png)

#### Skip Token Encryption Certificate

![Skip Token Encryption Certificate](images/adfs_007.png "Skip Token Encryption Certificate")

#### Skip WS-Federation and SAML

![Skip WS-Federation and SAML](images/adfs_008.png  "Skip WS-Federation and SAML")

#### Add Relying Party trust identifier

* Enter `silentcircle-entapi://rpid` in `Relying party trust identifier` and
  click `Add`

![Add Relying Party trust identifier](images/adfs_009.png  "Add Relying Party trust identifier")

* Click `Next` to accept the trust identifier.

![Accept trust identifier](images/adfs_010.png  "Accept trust identifier")

#### Optional: Configure MFA

* We skip this step here, but you are free to configure MFA as desired.

![Optional: Configure MFA](images/adfs_011.png  "Optional: Configure MFA")

#### Choose Issuance Authorization Rules

* We will restrict access in a later step; for now, permit all users to access
  this Relying Party.

![Choose Issuance Authorization Rule](images/adfs_012.png  "Choose Issuance Authorization Rule")

#### Add Trust to the database

![Add Trust to the database](images/adfs_013.png  "Add Trust to the database")

#### Close the wizard

* Click `Close`. This will launch the `Edit Claims Rules Dialog`.

![Close the wizard](images/adfs_014.png  "Close the wizard")

### Configure Claims Rules

#### Add Issuance Transform Rule

* The `Edit Claims Rules for Silent Circle Enterprise Client` wizard should be
  running now.
* On the `Issuance Transform Rules` tab, click on `Add Rule...`

![Add Issuance Transform Rule](images/adfs_015.png  "Add Issuance Transform Rule")

#### Accept the `Send LDAP Attributes as Claims` template.

![Accept the Send LDAP Attributes as Claims template](images/adfs_016.png  "Accept the Send LDAP Attributes as Claims template")

#### Configure Temp Claim Rule

* Type "Temp" as the claim rule name (we'll be copying this later and deleting
  it).
* Select `Active Directory` as the attribute store.

![Configure Claim Rule](images/adfs_017.png  "Configure Claim Rule")

#### Add LDAP attributes

* Add the following LDAP attribute to Outgoing claim type mappings:
  * `objectGUID` to `sub`
  * `User-Principal-Name` to `email`
  * `displayName` to `name` (note that the Wizard keeps changing this to `Name`
    - allow it to do so for now; we'll change it later).

![Add LDAP Attributes - objectGUID](images/adfs_019.png  "Add LDAP Attributes - objectGUID")

![Add LDAP Attributes - UPN](images/adfs_020.png  "Add LDAP Attributes - UPN")

![Add LDAP Attributes - displayName](images/adfs_021.png  "Add LDAP Attributes - displayName")

![Add LDAP Attributes - Keeps uppercasing Name](images/adfs_022.png  "Add LDAP Attributes - Keeps uppercasing Name")

* Click `Finish`.

#### Copy Claim Rule Language

* Click `Edit Rule...` and then `View Rule Language`. Copy the selected text
  (right-click, then `Copy`).

![Edit rule](images/adfs_024.png  "Edit rule")

![View rule language](images/adfs_025.png  "View rule language")

![Copy rule language](images/adfs_027.png  "Copy rule language")

* Click `OK`, then `Cancel` to exit the rule editor.

![Exit rule editor](images/adfs_029.png  "Exit rule editor")

#### Add Custom Rule

* `Add rule...` to create a new rule based on `Send Claims Using a Custom Rule`.

![Add custom rule](images/adfs_030.png  "Add custom rule")

![Send claims using a custom rule](images/adfs_032.png  "Send claims using a custom rule")

* Name it "Send Silent Circle Enterprise Client Claims` and paste the copied
  text into it.
* Delete the text `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/`.

![Fix name claim](images/adfs_033.png  "Fix name claim")

*  What should be left is `name`.

![Fix name claim 2](images/adfs_035.png  "Fix name claim 2")

* Click `Finish`.

#### Delete temp rule

![Delete Temp rule](images/adfs_036.png  "Delete Temp rule")

* Delete the `Temp` rule.
* Press `OK`.

### Add Issuance Authorization Rules

The precise details will vary widely, but you will most likely want to restrict
which employees can use Silent Circle. This can be done using Issuance
Authorization Rules. If an employee tries to authenticate for a Silent Circle
resource (like Silent Phone), but is blocked by this rule, the employee will be
prevented by AD FS from authenticating, and will not be authorized to use
Silent Circle.

In this chapter we add a simple rule based on a user group that was previously
added.

* Select the `Issuance Authorization Rules` tab in `Edit Claim Rules`, and
  click on `Add Rule...`.

![Add issuance authorization rule](images/adfs_039.png  "Add issuance authorization rule")

* Select `Permit or Deny Users Based on an Incoming Claim`.

![Select Permit or Deny Users Based on an Incoming Claim](images/adfs_040.png  "Select `Permit or Deny Users Based on an Incoming Claim")

* Type in a rule name like `Authorize Silent Circle group members`.
* Select `Group SID` as an Incoming Claim Type.

![Authorize Silent Circle group members](images/adfs_041.png  "Authorize Silent Circle group members")

* Ensuring that the claim type is still `Group SID`, click `Browse` to select
  an incoming claim rule.

![Select an incoming claim rule](images/adfs_042.png  "Select an incoming claim rule")

* In the `Select User, Computer, or Group` dialog box, start typing in the
  group name. In this example, we've typed in `Silent Cir` and deliberately not
  completed it.

![Select User, Computer, or Group](images/adfs_043.png  "Select User, Computer, or Group")

* Now, click `Check Names` and the name will be auto-completed if possible.
  Otherwise, type in the full group name and click `Check names` again,
  followed by `OK`.

![Click Check Names](images/adfs_044.png  "Click Check Names")

* Ensure that all the fields are correct as shown:
    * Incoming claim type: `Group SID`
    * Incoming claim value: (varies by installation)
    * Radio button selected: `Permit access to users with this incoming claim`.
* Click `Finish`.

![Ensure that all the fields are correct](images/adfs_045.png  "Ensure that all the fields are correct")

* Remove the default rule, `Permit Access to All Users`.

![Remove default rule](images/adfs_046.png  "Remove default rule")

* There should only be one rule left; the one we just added. Click `OK`.

![](images/adfs_048.png)

* Finally, we see the `Silent Circle Relying Party` Enterprise Trust rule we've
  been working on.

![Silent Circle Relying Party Enterprise Trust rule](images/adfs_049.png  "Silent Circle Relying Party Enterprise Trust rule")

### Configure Silent Circle ADFS OAuth2 Client

This is the last step. In this step we need to configure the Silent Circle
OAuth2 client.

In a PowerShell window, type in the following command:

```ps1
Add-AdfsClient -ClientId SCEntClient `
  -Name 'Silent Circle Enterprise Client' `
  -Description 'Silent Circle Enterprise Client' `
  -RedirectURI https://accounts.silentcircle.com/sso/oauth2/return/,https://accounts-dev.silentcircle.com/sso/oauth2/return/,https://localsc.ch/sso/oauth2/return/,http://localsc.ch:8000/sso/oauth2/return/
```

To check it, type in

    Get-AdfsClient 'Silent Circle Enterprise Client'

Sample output is shown below.

```ps1
PS C:\Users\Administrator> Get-AdfsClient 'Silent Circle Enterprise Client'


RedirectUri : {http://localsc.ch:8000/sso/oauth2/return/, https://accounts.silentcircle.com/sso/oauth2/return/,
              https://accounts-dev.silentcircle.com/sso/oauth2/return/, https://localsc.ch/sso/oauth2/return/}
Name        : Silent Circle Enterprise Client
Description : Silent Circle Enterprise Client
ClientId    : SCEntClient
BuiltIn     : False
Enabled     : True
ClientType  : Public
```

<a name="scatp"></a>

## Acceptance Test Procedure

At this stage, the integration configuration should have been
completed, and now we need to test it.

* Test series SP must be run once for each supported Silent Phone
  device.
* Test series SW should be run at least once with a supporte web
  browser.

<a name="atpsp1"></a>

### SP1: Provision Silent Phone using SSO

#### Test equipment

* Test device: A supported smartphone.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has valid credentials and an active account on your
  federated identity system.
* Test user's account belongs to a group in your environment that is
  authorized to use Silent Circle.

#### Procedure

* Ensure that the test device has no Silent Phone installed. If it
  does, uninstall it.
* Download and install Silent Phone from the appropriate app store.
* Launch Silent Phone and accept notifications, if prompted.
* You should see a login form on the device.
* Attempt to sign on the test user. The user id will be in the form
  `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the user's credentials and send the form.
* Depending on your policies, you may be required to engage in a
  multi-factor authentication process or other activities that are
  part of the regular single sign-on process. It is assumed that you
  are able to complete these successfully.
* After a brief pause while the app provisions with Silent Circle,
  you should be presented with the app's main page.
* Ensure that you can interact with the app by changing to the
  message view, the call view, looking at the settings, and so on.
* Ensure that the user's name and email address are displayed
  correctly.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are accepted by your SSO environment.
* Silent Phone app is provisioned and user is able to interact with
  it.
* User's name and email address are displayed correctly.

<a name="atpsp2"></a>

### SP2: Silent Phone SSO (unauthorized user)

The purpose of this test is to ensure that your federation group
policy, authorizing Silent Circle access only to users who comply
with that policy, rejects users that should not be authorized.

#### Test equipment

* Test device: A supported smartphone.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has valid credentials and an active account on your
  federated identity system.
* Test user's account **does not** belong to the group in your
  environment that is authorized to use Silent Circle.

#### Procedure

* Ensure that the test device has no Silent Phone installed. If it
  does, uninstall it.
* Download and install Silent Phone from the appropriate app store.
* Launch Silent Phone and accept notifications, if prompted.
* You should see a login form on the device.
* Attempt to sign on the test user. The user id will be in the form
  `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the user's credentials and send the form.
* The user's access should be rejected.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are rejected by your SSO environment with a
  suitable error message.

<a name="atpsp3"></a>

### SP3: Silent Phone SSO (invalid user)

The purpose of this test is to ensure that attempts to sign on by a
user that has no active account on your federated identity system is
rejected.

#### Test equipment

* Test device: A supported smartphone.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has invalid or nonexistent credentials on your federated
  identity system.

#### Procedure

* Ensure that the test device has no Silent Phone installed. If it
  does, uninstall it.
* Download and install Silent Phone from the appropriate app store.
* Launch Silent Phone and accept notifications, if prompted.
* You should see a login form on the device.
* Attempt to sign on the fake test user. The user id will be in the
  form `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the user's credentials and send the form.
* The user's access should be rejected.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are rejected by your SSO environment with a
  suitable error message.

<a name="atpsp3"></a>

### SP4: Silent Phone SSO sanity test

The purpose of this test is to ensure that users who provisioned
their Silent Phone applications using SSO can locate, and
communicate with, each other.

#### Test equipment

* Test devices: Two supported smartphones.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test users have valid credentials and an active account on your
  federated identity system.
* Test user accounts belong to a group in your environment that is
  authorized to use Silent Circle.

#### Procedure

* For each smartphone, perform test [SP1](#atpsp1).
* User A texts user B with the Silent Phone application.
* User A calls user B with the Silent Phone application. Note that
  this excludes calls made to regular landline or mobile numbers.
* Repeat the above, except that user B initiates the communication.

#### Acceptance criteria

* Users are able to send and receive SP text messages.
* Users are able to make and receive SP to SP voice calls, and
  converse with each other.

<a name="atpsw1"></a>

### SW1: Sign On to Silent Circle Web using SSO

#### Test equipment

* Test device: A supported web browser.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has valid credentials and an active account on your
  federated identity system.
* Test user's account belongs to a group in your environment that is
  authorized to use Silent Circle.

#### Procedure

* Ensure that you are signed out of your SSO environment and out of
  Silent Circle Web.
* Browse to one of the following links:
    * If using test environment: https://accounts-dev.silentcircle.com/
    * If using production environment: https://accounts.silentcircle.com/
* You should see a Silent Circle login form on the browser.
* Click on the link to login with SSO.
* Attempt to sign on the test user. The user id will be in the form
  `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the user's credentials and send the form.
* Depending on your policies, you may be required to engage in a
  multi-factor authentication process or other activities that are
  part of the regular single sign-on process. It is assumed that you
  are able to complete these successfully.
* You should be presented with the user's account page. If this is
  the first time the user has signed on to the web site, some
  conditions may need to be accepted.
* Check that the user's name and email address are displayed
  correctly.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are accepted by your SSO environment.
* User is granted access to that users' Silent Circle home page.
* User's name and email address are displayed correctly.

<a name="atpsw2"></a>

### SW2: Sign On to Silent Circle Web using SSO (unauthorized user)

The purpose of this test is to ensure that your federation group
policy, authorizing Silent Circle access only to users who comply
with that policy, rejects users that should not be authorized.

#### Test equipment

* Test device: A supported web browser.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has valid credentials and an active account on your
  federated identity system.
* Test user's account **does not** belong to a group in your
  environment that is authorized to use Silent Circle.

#### Procedure

* Ensure that you are signed out of your SSO environment and out of
  Silent Circle Web.
* Browse to one of the following links:
    * If using test environment: https://accounts-dev.silentcircle.com/
    * If using production environment: https://accounts.silentcircle.com/
* You should see a Silent Circle login form on the browser.
* Click on the link to login with SSO.
* Attempt to sign on the test user. The user id will be in the form
  `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the user's credentials and send the form.
* The user's access should be rejected.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are rejected by your SSO environment with a
  suitable error message.

<a name="atpsw3"></a>

### SW3: Sign On to Silent Circle Web using SSO (invalid user)

The purpose of this test is to ensure that attempts to sign on by a
user that has no active account on your federated identity system is
rejected.

#### Test equipment

* Test device: A supported web browser.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Test user has invalid or nonexistent credentials on your federated
  identity system.

#### Procedure

* Ensure that you are signed out of your SSO environment and out of
  Silent Circle Web.
* Browse to one of the following links:
    * If using test environment: https://accounts-dev.silentcircle.com/
    * If using production environment: https://accounts.silentcircle.com/
* You should see a Silent Circle login form on the browser.
* Click on the link to login with SSO.
* Attempt to sign on the test user. The user id will be in the form
  `user@example.com`.
* You should be taken to your company's SSO sign-on page.
* Enter the fake user's credentials and send the form.
* The user's access should be rejected.

#### Acceptance criteria

* User is presented with your single sign-on page.
* User's credentials are rejected by your SSO environment with a
  suitable error message.

<a name="atpsw4"></a>

### SW4: Sign out of Silent Circle Web

The purpose of this test is to ensure that when you sign out of
Silent Circle web and sign in as a different user, the SSO system
forces a reauthentication, and the new user is signed on correctly.

#### Test equipment

* Test device: A supported web browser.
* Network connection: WiFi with unrestricted inbound and outbound
  firewall.

#### Preconditions

* Two sets of test user accounts with has valid credentials and
  active accounts on your federated identity system.
* Both test user's accounts belong to a group in your environment
  that is authorized to use Silent Circle.

#### Procedure

* Ensure that you are signed out of your SSO environment and out of
  Silent Circle Web.
* Browse to one of the following links:
    * If using test environment: https://accounts-dev.silentcircle.com/
    * If using production environment: https://accounts.silentcircle.com/
* You should see a Silent Circle login form on the browser.
* Click on the link to login with SSO.
* Sign on test user 1.
* Sign off test user 1.
* Sign on test user 2.

#### Acceptance criteria

* Test user 2 is presented with your single sign-on page.
* Test user 2's credentials are accepted by your SSO environment.
* Test user 2 is granted access to that users' Silent Circle home
  page.
* Test user 2's name and email address are displayed correctly.

# Appendixes

<a name="sscafitr"></a>

## Appendix A: Silent Circle AD FS Issuance Transform Rules

* Claim store issuer: Active Directory
* Claim Type: `http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname`
* Transforms as shown below.

| Active Directory attribute | Silent Circle claim |
| -------------------------- | --------------------|
| objectGUID                 | sub                 |
| userPrincipalName          | email               |
| displayName                | name                |

**AD FS Rule Code**

```ps1
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/windowsaccountname",
   Issuer == "AD AUTHORITY"]
   => issue(store = "Active Directory",
      types = ("sub", "email", "name"),
      query = ";objectGUID,userPrincipalName,displayName;{0}",
      param = c.Value);
```

<a name="sscafiar"></a>

## Appendix B: Silent Circle AD FS Issuance Authorization Rules (Example only)

You will probably want to restrict which of your users are allowed to use
Silent Circle. Your AD FS configuration will need Issuance Authorization Rules
that only allow a subset of users to be authorized. When an unauthorized user
tries to sign on to your AD FS site, the sign-on attempt will be rejected by
your site (not by Silent Circle).

Rules will differ widely depending on your organizational policies, so it is
not possible to provide more than a sample rule set. The following rule allows
only users that belong to a group with Group Security ID
`S-1-5-21-207668378-2981979776-1947477811-1112`:

**AD FS Rule Code**

```
c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid",
   Value =~ "^(?i)S-1-5-21-207668378-2981979776-1947477811-1112$"]
 => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit",
          Value = "PermitUsersWithClaim");
```

<a name="sscafrpis"></a>

## Appendix C: Silent Circle AD FS Relying Party Integration Cmdlets

Some PowerShell cmdlets are available for download from Silent
Circle's [GitHub SSO repository][SC.GitHub.SSO] that can assist with
automating Silent Circle's AD FS integration.

To download, you can clone the GitHub repository as follows:

    git clone https://github.com/SilentCircle/sso-integration.git

You can also download the repository as a ZIP file using
[this link](https://github.com/SilentCircle/sso-integration/archive/master.zip).

From PowerShell, you can download and extract the ZIP file as follows:

```ps1
Invoke-WebRequest -Uri https://github.com/SilentCircle/sso-integration/archive/master.zip -OutFile SilentCircleSSO.zip
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory("SilentCircleSSO.zip", "SilentCircle")
```

The files will be in the SilentCircle directory.

```
PS C:\Users\Administrator> cd .\SilentCircle\sso-integration-master\adfs\3.0\scripts

PS C:\Users\Administrator\SilentCircle\sso-integration-master\adfs\3.0\scripts> dir


    Directory: C:\Users\Administrator\SilentCircle\sso-integration-master\adfs\3.0\scripts


Mode                LastWriteTime     Length Name
----                -------------     ------ ----
-a---         4/28/2016  11:17 AM      10750 Add-SilentCircleRelyingPartyTrust.ps1
-a---         4/28/2016  11:17 AM       3330 Remove-SilentCircleRelyingPartyTrust.ps1
```

<!-- References -->

[SC.GitHub.SSO]: https://github.com/SilentCircle/sso-integration "SC GitHub SSO repository"
[ADFS 3.0]: https://technet.microsoft.com/en-us/library/hh831502.aspx "Active Directory Federation Services v3.0"
[CORS]: http://www.w3.org/TR/access-control/ "Cross-Origin Resource Sharing"
[RFC6749]: http://tools.ietf.org/html/rfc6749 "RFC6749 (OAuth 2.0)"
[OAuth.Assertions]: http://tools.ietf.org/OAuth.Assertions/draft-ietf-oauth-assertions-17 "OAuth.Assertions"
[OAuth.JWT]: http://tools.ietf.org/OAuth.JWT/draft-ietf-oauth-jwt-bearer-10 "OAuth.JWT"
[OAuth.Responses]: http://openid.net/specs/oauth-v2-multiple-response-types-1_0.html "OAuth 2.0 Multiple Response Type Encoding Practices"

<link href="styles/sc-metro-vibes-light.css" rel="stylesheet">

<!--- vim: set textwidth=68 formatoptions+=t et : -->
