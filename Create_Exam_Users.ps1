Import-Module ActiveDirectory

function Copy-OUs {
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    $BaseOU,
    [Parameter(Mandatory=$true, Position=1)]
    $DestOU
  )

  <#
        .SYNOPSIS
        Clones an Active Directory OU structure to a new OU.

        .DESCRIPTION
        .

        .PARAMETER BaseOU
        Specifies the base OU where sub OUs are to be found.

        .PARAMETER DestOU
        Specifies the destination OU where sub OUs are to be copied.

        .INPUTS
        None. You cannot pipe objects Copy-OUs

        .EXAMPLE
        C:\PS> Copy-OUs -BaseOU "CN=Users,DC=domain,DC=local"  -DestOU "CN=Exams,CN=Users,DC=domain,DC=local"

        .LINK
        Online version: https://github.com/mavhc/powershell/

  #>
  $SubOUs = Get-ADOrganizationalUnit -SearchBase $BaseOU -SearchScope Subtree -Filter *
  #write-output $SubOUs

  $DestOUName = ($destOU -split ',*..=')[1]
  foreach ($OU in $SubOUs) {
    #write-output $OU
    $ShadowGroup = $OU.Name
    #write-output "Group: $ShadowGroup"
    try {
        if ($ShadowGroup -ne $DestOUName) {
            write-output "Creating OU"
            New-ADOrganizationalUnit -Name $ShadowGroup -Path $DestOU
        }
    }
    catch { Write-Warning $_ }
  }
}

function Copy-Users {
  Param(
    [Parameter(Mandatory=$true, Position=0)]
    $BaseOU,
    [Parameter(Mandatory=$true, Position=1)]
    $DestOU,
    [Parameter(Mandatory=$true, Position=2)]
    $UsernamePrefix,
    [Parameter(Mandatory=$false, Position=3)]
    $AddGroup

  )

  <#
        .SYNOPSIS
        Clones userse in an Active Directory OU structure to a new OU.

        .DESCRIPTION
        .

        .PARAMETER BaseOU
        Specifies the base OU where sub OUs are to be found.

        .PARAMETER DestOU
        Specifies the destination OU where sub OUs are to be copied.

        .PARAMETER UsernamePrefix
        Specifies the prefix to add to the cloned username.

        .PARAMETER AddGroup
        Specifies the AD group to add to the user.

        .INPUTS
        None. You cannot pipe objects Copy-OUs

        .EXAMPLE
        C:\PS> Copy-OUs -BaseOU "CN=Users,DC=domain,DC=local"  -DestOU "CN=Exams,CN=Users,DC=domain,DC=local"

        .LINK
        Online version: https://github.com/mavhc/powershell/

  #>
  $SubOUs = Get-ADOrganizationalUnit -SearchBase $BaseOU -SearchScope OneLevel -Filter *
  #write-output $SubOUs
  $examTemplateUser = get-aduser -Identity "ExamTemplate"
  $DestOUName = ($destOU -split ',*..=')[1]
  foreach ($OU in $SubOUs) {
    #write-output "OU = $OU"
    $ShadowGroup = $OU.Name
    write-output "Group: $ShadowGroup"
    try {
        if ($ShadowGroup -ne $DestOUName) {
            #write-output "searching $OU for users"
            $users = Get-ADUser -Filter * -SearchBase $OU -SearchScope OneLevel
            ForEach ($user in $users) {
                $userDN = $user.distinguishedname
                #write-output "user $userDN"
                $userLeaf = $userDN -replace $BaseOU
                $newUser = $userLeaf.substring(0,3) + $UsernamePrefix + $userLeaf.substring(3) + $DestOU
                $path = $newUser.substring($newUser.indexOf(",")+1)
                [System.Net.HttpWebRequest]::DefaultWebProxy = New-Object System.Net.WebProxy($null)
                $randomPasswordString = Invoke-WebRequest -UseBasicParsing -Uri https://www.dinopass.com/password/simple | Select-Object -ExpandProperty content
                #$randomPasswordString = "bob"
                $randomPassword = ConvertTo-SecureString -String $randomPasswordString -AsPlainText -Force
                $surname = $user.name
                $username = "Exam-$surname"
                $upn = $username + "@derrymount.local"
                write-output $username $randomPasswordString
                New-ADUser -AccountPassword $randomPassword -CannotChangePassword $true -GivenName "Exam" -Surname $surname -Name $username -Instance $examTemplateUser -Path $path -UserPrincipalName $upn
            }
        }
    }
    catch { Write-Warning $_ }
  }
}


$source="OU=Pupils,OU=Users,OU=School,DC=domain,DC=local"
$dest  ="OU=PupilsExams,OU=Users,OU=School,DC=domain,DC=local"
Copy-OUs $OU1 $OU2
Copy-Users $OU1 $OU2 "Exam-"
