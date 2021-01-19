$class = $args[0]
write-output "restarting Impero for class $class"
if ($class.substring(0,1) -eq "m")
{$ldappath = 'LDAP://OU=' + $class + ',OU=Laptops,OU=.....,DC=local'}
else {
$ldappath = 'LDAP://OU=' + $class + ',OU=Laptops,OU=......,DC=local'
}
write-output $ldappath

# Not using Get-ADComputer as that requires things installing
$DirSearcher = New-Object DirectoryServices.DirectorySearcher([adsi]$ldappath)
$DirSearcher.Filter = '(objectClass=Computer)'
$computers = $DirSearcher.FindAll().GetEnumerator() | ForEach-Object { $_.Properties.name }

# Convert to array because that seems to make it work
$computers1 = @() 

foreach($t in $computers)
{
    if($t -ne $null -and $temp -ne "")
    {
        $computers1 += $t
    }
}
write-output  $computers1

# This part requires Remote permissions for the user to connect to the computer, and changes to permissions for the service so that the user can start/stop it
Invoke-Command -ComputerName $computers1 -ScriptBlock {restart-service imperoclientsvc }
