# At some point install printer drivers into driver store in a startup script
# pnputil /a '\\server\share$\path\to\printer\driver\file.inf'

# this script run as a standard user
$CurrentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$WindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentUser)

Add-printerport -Name "TCPPort:dns.name.of.printer" -PrinterHostAddress "dns.name.of.printer" -ErrorAction SilentlyContinue

Add-PrinterDriver -name "Kyocera TASKalfa 4052ci KX" -ErrorAction SilentlyContinue
Add-PrinterDriver -name "Kyocera TASKalfa 4053ci v4 KX (XPS)" -ErrorAction SilentlyContinue

if ([System.DirectoryServices.ActiveDirectory.ActiveDirectorySite]::GetComputerSite().Name -eq "Site 1") {
  Add-Printer -Name "Name Shown To Users" -PortName "TCPPort:dns.name.of.printer" -driver "Kyocera TASKalfa 4053ci v4 KX (XPS)" -ErrorAction SilentlyContinue
  set-printconfiguration -color $false -printername "Name Shown To Users"  -ErrorAction SilentlyContinue
  $printer = Get-CimInstance -Class Win32_Printer -Filter "Name='Name Shown To Users'"
  Invoke-CimMethod -InputObject $printer -MethodName SetDefaultPrinter
  (New-Object -ComObject WScript.Network).SetDefaultPrinter('Name Shown To Users')
  if (-not $WindowsPrincipal.IsInRole("A_Group_Name")) {
    Add-Printer -Name "Another Printer"    -PortName "TCPPort:another.printer.dns.name"   -driver "Kyocera TASKalfa 4053ci v4 KX (XPS)" -ErrorAction SilentlyContinue
    Add-Printer -Name "Another Printer v3" -PortName "TCPPort:another.printer.dns.name"   -driver "Kyocera TASKalfa 4052ci KX" -ErrorAction SilentlyContinue
    set-printconfiguration -color $false -printername "Another Printer" -ErrorAction SilentlyContinue
    if ($WindowsPrincipal.IsInRole("A_Different_Group")) {
      $printer = Get-CimInstance -Class Win32_Printer -Filter "Name='Another Printer'"
      Invoke-CimMethod -InputObject $printer -MethodName SetDefaultPrinter
    }
  }
  else {
    Remove-Printer -Name "Another Printer"  -ErrorAction SilentlyContinue
  }
}
