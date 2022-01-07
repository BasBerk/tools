#Versie 2.1 (26-7-2019) Labels aangepast
#created for the helpdesk, to give acces persons access to a sharedmailbox. Should not be needed to do it like this
#Requires -RunAsAdministrator

$domainfilter = "domain.com"
Function Connect2Office365 {
    Write-Host -ForegroundColor Red 'Geen Sessie, log in met je admin credentials'
    Get-PSSession | Remove-PSSession
    Write-Host -ForegroundColor Red "Enter your Office 365 Administrator Username and Password"
    $cred = Get-Credential
    Write-Host "Connecting to Office 365..." -foregroundcolor "yellow"
    $msoExchangeURL = “https://ps.outlook.com/powershell/”
    $session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri $msoExchangeURL -Credential $cred -Authentication Basic -AllowRedirection
    Import-PSSession $session
    }




Function ClearScriptVariables {
    Clear-Variable UserTarget, UserTarget1, UserSrc, UserSrc1 -ErrorAction SilentlyContinue
    }


$SessionAvail = Get-PSSession |Select-Object Computername | select -ExpandProperty computername
if ($SessionAvail -eq 'ps.outlook.com') {

    Write-Host -ForegroundColor Green 'Sessie is er GO GO GO'

}
else { Connect2Office365
    
    
}
$Exit = '1'
While ($Exit = '1'){
ClearScriptVariables
 $Menu = [ordered]@{

  1 = 'Stel Full Access Permissions in'
  2 = 'Stel send as rechten in'
  3 = 'Stel Full Access en Send As rechten in'
  4 = 'Remove all right for a specific user on a mailbox'
  5 = 'controleer de rechten op een mailbox'
  6 = 'Exit / cancel'
  }

  

  $Result = $Menu | Out-GridView -PassThru  -Title 'Wat wil je doen?'

  Switch ($Result)  {

  {$Result.Name -eq 1} {  
  $UserTarget = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttypedetails  | Out-GridView -Title "Op welke mailbox wil je rechten geven?" -PassThru 
  $UserTarget1 = $UserTarget |Select-Object -ExpandProperty alias
  $UserSrc = Get-Mailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttype  | Out-GridView  -Title "Wie moet de rechten krijgen op de mailbox" -PassThru 
  $UserSrc1 = $UserSrc |select -ExpandProperty alias
  Add-MailboxPermission -Identity $UserTarget1 -User $UserSrc1 -AccessRights FullAccess -AutoMapping $false
  
  }

  {$Result.Name -eq 2} { 
  $UserTarget = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttypedetails  | Out-GridView -Title "Op welke mailbox wil je rechten geven?" -PassThru 
  $UserTarget1 = $UserTarget |Select-Object -ExpandProperty alias
  $UserSrc = Get-Mailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttype  | Out-GridView -Title "Wie moet de verzend rechten krijgen op de mailbox" -PassThru
  $UserSrc1 = $UserSrc |select -ExpandProperty alias
  Add-RecipientPermission $UserTarget1  -AccessRights SendAs -Trustee $UserSrc1 -Confirm:$false
  
  }

  {$Result.Name -eq 3} {
  $UserTarget = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttypedetails  | Out-GridView -Title "Op welke mailbox wil je rechten geven?" -PassThru 
  $UserTarget1 = $UserTarget |Select-Object -ExpandProperty alias
  $UserSrc = Get-Mailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttype  | Out-GridView -Title "Wie moet alle rechten krijgen op de mailbox" -PassThru
  $UserSrc1 = $UserSrc |select -ExpandProperty alias
  Add-MailboxPermission -Identity $UserTarget1 -User $UserSrc1 -AccessRights FullAccess -InheritanceType all -AutoMapping $false
  Add-RecipientPermission $UserTarget1  -AccessRights SendAs -Trustee $UserSrc1 -Confirm:$false
  
  }   

  {$Result.Name -eq 4} {
  $UserTarget = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttypedetails  | Out-GridView -Title "Op welke mailbox moeten de rechten ingetrokken worden?" -PassThru 
  $UserTarget1 = $UserTarget |Select-Object -ExpandProperty alias
  $UserSrc= Get-MailboxPermission $UserTarget1 |? user -Like "*$domainfilter" |Out-GridView -Title "kies de persoon welke we ontdoen van zijn rechten" -PassThru
  $UserSrc1 = $UserSrc |select -ExpandProperty User
  remove-MailboxPermission -Identity $UserTarget1 -User $UserSrc1 -AccessRights FullAccess -InheritanceType all -Confirm:$false
  Remove-RecipientPermission $UserTarget1  -AccessRights SendAs -Trustee $UserSrc1 -Confirm:$false
  
  }
  
  {$Result.Name -eq 5} {
  $UserTarget = Get-Mailbox -RecipientTypeDetails SharedMailbox -ResultSize unlimited | select name, alias, PrimarySmtpAddress, recipienttypedetails  | Out-GridView -Title "Van welke mailbox wil je de rechten zien?" -PassThru 
  $UserTarget1 = $UserTarget |Select-Object -ExpandProperty alias
  $UserSrc= Get-MailboxPermission $UserTarget1 |? user -Like "*$domainfilter" |Out-GridView -Title "Deze personen hebben rechten op de mailbox" -PassThru
  $UserSrc1 = $UserSrc |select -ExpandProperty User
  
  }

  {$Result.Name -eq 6} {
   Get-PSSession |Select-Object Computername | ? computername -eq ps.outlook.com |Remove-PSSession
   $Exit = '0'
   ClearScriptVariables
   exit
   }

} 
}
