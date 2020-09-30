Import-Module ActiveDirectory

function Sync-OUs {
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    $BaseOU
  )

  <#
        .SYNOPSIS
        Syncs an Active Directory group with an OU of the same name.

        .DESCRIPTION
        Adds or removes members of an AD group to be in sync with members of an AD OU with the same name

        .PARAMETER BaseOU
        Specifies the base OU where sub OUs are to be found.

        .INPUTS
        None. You cannot pipe objects to Snc-OUs

        .EXAMPLE
        C:\PS> SyncOUs -BaseOU "CN=Users,DC=domain,DC=local"

        .LINK
        Online version: https://github.com/mavhc/powershell/ShadowGroupsSync.ps1

  #>
  $SubOUs = Get-ADOrganizationalUnit -SearchBase $BaseOU -SearchScope OneLevel -Filter *
  
  foreach ($OU in $SubOUs) {
    $ShadowGroup = $OU.Name
    write-output $ShadowGroup
    write-output "Removing"
    Get-ADGroupMember –Identity $ShadowGroup | Where-Object {$_.distinguishedName –NotMatch $OU} |
    ForEach-Object {
        write-output $_.distinguishedName
        Remove-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup –Confirm:$false
    }
    write-output "Adding"
    Get-ADUser –SearchBase $OU –SearchScope OneLevel –LDAPFilter "(!memberOf=$ShadowGroup)" |
    ForEach-Object {
        write-output $_.distinguishedName
        Add-ADPrincipalGroupMembership –Identity $_ –MemberOf $ShadowGroup}
    }
}

$OU1="OU=...,DC=..."
$OU2="OU=...,DC=..."

Sync-OUs $OU1
Sync-OUs $OU2
