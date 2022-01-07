#######################################################################################
##
## Script: UpdateAddressLists.ps1
## Omschrijving: Update alle (global) addresslists
## Auteur: Bas 
## Versie: 1.0
## Datum: 22-3-2017
##
#######################################################################################

Add-PSsnapin *Exchange* -ErrorAction SilentlyContinue
$Globaladdresslists = Get-GlobalAddressList 
$Addresslists = Get-AddressList

foreach ($Globaladdresslist in $Globaladdresslists){
Update-GlobalAddressList -Identity $Globaladdresslist}

foreach ($Addresslist in $Addresslists) {
Update-AddressList -Identity $Addresslist}


