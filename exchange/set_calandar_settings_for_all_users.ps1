#######################################################################################
##
## Script: set_calandar_settings_for_all_users.ps1
## Omschrijving: Pas de kalender rechten aan voor alle gebruikers. Currently for dutch, change aganda to calendar
## Auteur: Bas 
## Versie: 1.0
## Datum: 2-2-2017
## Bijgewerkt: nvt
##
## Aanpassingen: nvt
#######################################################################################

#Haal alle mailboxen maar filter op AddressbookPolicy
$allmailbox = Get-Mailbox * | ? {$_.AddressBookPolicy -eq "NAME"} 

#Pas voor alle mailboxen het default account (iedereen) en geef de gewenste rechten.
#meer info over rechten https://technet.microsoft.com/en-us/library/ff522363(v=exchg.160).aspx

Foreach ($Mailbox in $allmailbox)

{Set-mailboxfolderpermission –identity ($Mailbox.alias+’:\agenda’) –user Default –Accessrights Reviewer }


#Voor 1 mailbox, geen onderdeel van actief script!!
#Set-MailboxFolderPermission -Identity "etsSanderS" -User Default -AccessRights Reviewer