# ADFS Integration for Silent Circle Enterprise Customers

## System Requirements

* Microsoft Windows Server 2012 R2
* Microsoft Active Directory Federation Services 3.0

## Configuration Steps

### Configure Active Directory Federation Services (ADFS)

This is where we add the Silent Circle trust relationship.

#### In Server Manager, select `Tools > AD FS Management`.

---

![AD FS Management](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_001.png  "AD FS Management")

---

#### Launch the `Add Relying Party Trust` Wizard

---

![Launch Add Relying Party Trust Wizard](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_002.png  "Launch Add Relying Party Trust Wizard")

---
#### Start the `Add Relying Party Trust` Wizard

![Start Add Relying Party Trust Wizard](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_003.png  "Start Add Relying Party Trust Wizard")


#### Select `Enter data about the relying party manually`

![Enter data about the relying party manually](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_004.png  "Enter data about the relying party manually")

---

#### Add Silent Circle information

* Enter "Silent Circle Enterprise Client" in `Display name`, and any notes that might be of interest.
* Click `Next`.

![Add Silent Circle information](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_005.png  "Add Silent Circle information")

---

#### Select AD FS Profile

![Select AD FS Profile](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_006.png) 

---

#### Skip Token Encryption Certificate

![Skip Token Encryption Certificate](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_007.png "Skip Token Encryption Certificate")
 
---

#### Skip WS-Federation and SAML

![Skip WS-Federation and SAML](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_008.png  "Skip WS-Federation and SAML")

---

#### Add Relying Party trust identifier

* Enter `silentcircle-entapi://rpid` in `Relying party trust identifier` and click `Add`

![Add Relying Party trust identifier](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_009.png  "Add Relying Party trust identifier")

---

* Click `Next` to accept the trust identifier.

![Accept trust identifier](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_010.png  "Accept trust identifier")

---

#### Optional: Configure MFA

* We skip this step here, but you are free to configure MFA as desired.

![Optional: Configure MFA](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_011.png  "Optional: Configure MFA")

---

#### Choose Issuance Authorization Rules

* We will restrict access in a later step; for now, permit all users to access this Relying Party.

![Choose Issuance Authorization Rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_012.png  "Choose Issuance Authorization Rule")

---

#### Add Trust to the database

![Add Trust to the database](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_013.png  "Add Trust to the database")

---

#### Close the wizard

* Click `Close`. This will launch the `Edit Claims Rules Dialog`.

![Close the wizard](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_014.png  "Close the wizard")

---

### Configure Claims Rules

#### Add Issuance Transform Rule

* The `Edit Claims Rules for Silent Circle Enterprise Client` wizard should be running now.
* On the `Issuance Transform Rules` tab, click on `Add Rule...`

![Add Issuance Transform Rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_015.png  "Add Issuance Transform Rule")

---

#### Accept the `Send LDAP Attributes as Claims` template.

![Accept the Send LDAP Attributes as Claims template](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_016.png  "Accept the Send LDAP Attributes as Claims template")

---

#### Configure Temp Claim Rule

* Type "Temp" as the claim rule name (we'll be copying this later and deleting it).
* Select `Active Directory` as the attribute store.

![Configure Claim Rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_017.png  "Configure Claim Rule")

---

#### Add LDAP attributes

* Add the following LDAP attribute to Outgoing claim type mappings:
  * `objectGUID` to `sub`
  * `User-Principal-Name` to `email`
  * `displayName` to `name` (note that the Wizard keeps changing this to `Name` - allow it to do so for now; we'll change it later).

![Add LDAP Attributes - objectGUID](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_019.png  "Add LDAP Attributes - objectGUID")

---

![Add LDAP Attributes - UPN](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_020.png  "Add LDAP Attributes - UPN")

---

![Add LDAP Attributes - displayName](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_021.png  "Add LDAP Attributes - displayName")

---

![Add LDAP Attributes - Keeps uppercasing Name](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_022.png  "Add LDAP Attributes - Keeps uppercasing Name")

* Click `Finish`.

---

#### Copy Claim Rule Language

* Click `Edit Rule...` and then `View Rule Language`. Copy the selected text (right-click, then `Copy`).

![Edit rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_024.png  "Edit rule")

---

![View rule language](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_025.png  "View rule language")

---

![Copy rule language](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_027.png  "Copy rule language")

---

* Click `OK`, then `Cancel` to exit the rule editor.

![Exit rule editor](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_029.png  "Exit rule editor")

---

#### Add Custom Rule

* `Add rule...` to create a new rule based on `Send Claims Using a Custom Rule`.

![Add custom rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_030.png  "Add custom rule")

---

![Send claims using a custom rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_032.png  "Send claims using a custom rule")

---

* Name it "Send Silent Circle Enterprise Client Claims` and paste the copied text into it.
* Delete the text `http://schemas.xmlsoap.org/ws/2005/05/identity/claims/`.

![Fix name claim](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_033.png  "Fix name claim")

---

*  What should be left is `name`.

![Fix name claim 2](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_035.png  "Fix name claim 2")

* Click `Finish`.

#### Delete temp rule

![Delete Temp rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_036.png  "Delete Temp rule")

* Delete the `Temp` rule.
* Press `OK`.

---

### Add Issuance Authorization Rules

The precise details will vary widely, but most companies will want to restrict which employees can use Silent Circle. This can be done using Issuance Authorization Rules. If an employee tries to authenticate for a Silent Circle resource (like Silent Phone), but is blocked by this rule, the employee will be prevented from authenticating, and will not be authorized to use Silent Circle.

In this chapter we add a simple rule based on a user group that was previously added. No doubt more elaborate rules will be desired, but this is a good starting point.

* Select the `Issuance Authorization Rules` tab in `Edit Claim Rules`, and click on `Add Rule...`.

![Add issuance authorization rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_039.png  "Add issuance authorization rule")

---

* Select `Permit or Deny Users Based on an Incoming Claim`.

![Select Permit or Deny Users Based on an Incoming Claim](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_040.png  "Select `Permit or Deny Users Based on an Incoming Claim")

---

* Type in a rule name like `Authorize Silent Circle group members`.
* Select `Group SID` as an Incoming Claim Type.

![Authorize Silent Circle group members](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_041.png  "Authorize Silent Circle group members")

---

* Ensuring that the claim type is still `Group SID`, click `Browse` to select an incoming claim rule.

![Select an incoming claim rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_042.png  "Select an incoming claim rule")

---

* In the `Select User, Computer, or Group` dialog box, start typing in the group name. In this example, we've typed in `Silent Cir` and deliberately not completed it.

![Select User, Computer, or Group](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_043.png  "Select User, Computer, or Group")

---

* Now, click `Check Names` and the name will be auto-completed if possible. Otherwise, type in the full group name and click `Check names` again, followed by `OK`.

![Click Check Names](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_044.png  "Click Check Names")

---

* Ensure that all the fields are correct as shown:
    * Incoming claim type: `Group SID`
    * Incoming claim value: (varies by installation)
    * Radio button selected: `Permit access to users with this incoming claim`.
* Click `Finish`.

![Ensure that all the fields are correct](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_045.png  "Ensure that all the fields are correct")

---

* Remove the default rule, `Permit Access to All Users`.

![Remove default rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_046.png  "Remove default rule")

---

* There should only be one rule left; the one we just added. Click `OK`.

![](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_048.png) 

---

* Finally, we see the `Silent Circle Relying Party` Enterprise Trust rule we've been working on.

![Silent Circle Relying Party Enterprise Trust rule](/home/efine/work/sc/adfs/ADFS-Integration-Customer-Responsibilities-images/adfs_049.png  "Silent Circle Relying Party Enterprise Trust rule")

---

### Configure Silent Circle ADFS OAuth2 Client

This is the last step. In this step we need to configure the Silent Circle OAuth2 client.

In a PowerShell window, type in the following command:

    Add-AdfsClient -ClientId SCEntClient `
      -Name 'Silent Circle Enterprise Client' `
      -Description 'Silent Circle Enterprise Client' `
      -RedirectURI https://accounts.silentcircle.com/sso/oauth2/return/,https://accounts-dev.silentcircle.com/sso/oauth2/return/,https://localsc.ch/sso/oauth2/return/,http://localsc.ch:8000/sso/oauth2/return/


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

