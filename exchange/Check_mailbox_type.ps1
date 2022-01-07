$mailboxen = 'abx@sds.nl','abff@sds.nl'

foreach ($mailbox in $mailboxen){ 
    try {
        $Global:ErrorActionPreference = ‘Stop’
        Get-Mailbox $mailbox  -ErrorAction stop | select primarysmtpaddress, RecipientTypeDetails -ErrorAction Stop
    }
    catch  {
        Write-Host $mailbox  "is geen mailbox"
    }
    
}