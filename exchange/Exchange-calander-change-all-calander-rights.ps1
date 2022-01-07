Add-PSsnapin *Exchange* -ErrorAction SilentlyContinue
#Check locale, agenda in dutch, calendar in EN, change in variable
#sets default calander settings for a user
Get-MailboxFolderStatistics -Identity USER -FolderScope Calendar


foreach($user in Get-Mailbox -RecipientTypeDetails UserMailbox) {

$cal = $user.alias+":\Agenda"

Set-MailboxFolderPermission -Identity $cal -User Default -AccessRights Reviewer

}


