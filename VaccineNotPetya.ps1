###############################################################################
##Script:           VaccineNotPetya.ps1
##
##Description:      https://www.bleepingcomputer.com/news/security/vaccine-not-killswitch-found-for-petya-notpetya-ransomware-outbreak/
##Created by:       Bas 
##Creation Date:    28-06-2017  
##
## Version:          0.2
##
$file = "C:\windows\perfc"
$chkifexists = Test-Path $file

If ($chkifexists -eq $true) {
Write-host "Yeah this system is vaccinated"
}
Else { New-Item $file -ItemType File
Set-ItemProperty $file -Name IsReadOnly $true
Write-Host "this system just got vaccinated"}