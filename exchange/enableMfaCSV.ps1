install-Module MsolService
Connect-MsolService
$Count = Get-MsolUser -EnabledFilter EnabledOnly  -all | Select-Object DisplayName,UserPrincipalName,@{N="MFAStatus"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}} #| Export-Csv C:\Users\bas.berkhout\Downloads\Usersenabled.csv -NoTypeInformation
$countEnabledBefore = $Count | Where-Object MFAstatus -Contains 'enabled' | Measure-Object |Select-Object -ExpandProperty Count
$countEnforcedBefore = $Count | Where-Object MFAstatus -Contains 'enforced' | Measure-Object |Select-Object -ExpandProperty Count

$source = import-csv -Delimiter ';' -Path "C:\****MFA batch list.csv"
#batch 1 12-12-2019
#batch 2 16-12-2019
#batch 555 6-1-2019
$order = 0
$selection = $source |Where-Object Batch -eq $order | Select-Object -ExpandProperty UserPrincipalName



foreach ($user in $selection)
{
   Write-Host -ForegroundColor Green 'Enable mfa for user' $user
    $st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
    $st.RelyingParty = "*"
    $st.State = "Enabled"
    $sta = @($st)
    Set-MsolUser -UserPrincipalName $user -StrongAuthenticationRequirements $sta 
    
}
$selection.Count
Write-Host -ForegroundColor Yellow "Activeren van de users uitgevoerd"
Write-Host -ForegroundColor Yellow "Start nu met tellingen"
$AllReadyActive = $source |Where-Object Batch -NE "" |Select-Object -ExpandProperty UserPrincipalname


$AllReadyActive.Count

foreach ($user in $AllReadyActive) {

$overview = Get-MsolUser -UserPrincipalName $user | Select-Object DisplayName,UserPrincipalName,@{N="MFA Status"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}} | Sort-Object 'MFA Status'

}
Write-Host -ForegroundColor DarkMagenta "De onderstaande gebruiker zouden door deze batch moeten geactiveerd moeten zijn"
foreach ($user in $selection){Write-Host -ForegroundColor DarkMagenta $user}
Write-Host -ForegroundColor DarkMagenta 'totaal ' $selection.Count
$Count = Get-MsolUser -all -EnabledFilter EnabledOnly  | Select-Object DisplayName,UserPrincipalName,@{N="MFAStatus"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}}
$count |Export-Csv C:\Users\bas.berkhout\Downloads\MFAstatusEnabled Only.csv -NoTypeInformation
$countEnabled = $Count | Where-Object MFAstatus -Contains 'enabled' | Measure-Object |Select-Object -ExpandProperty Count
$countEnforced = $Count | Where-Object MFAstatus -Contains 'enforced' | Measure-Object |Select-Object -ExpandProperty Count
Write-Host $overview
Write-Host -ForegroundColor Green "Er waren" $countEnabledBefore 'gebruikers met de status enabled voor het uitvoeren van de query, nu zijn er' $countEnabled 'met de status enabled'
Write-Host -ForegroundColor Green "Er waren" $countEnforcedBefore 'gebruikers met de status Enforced voor het uitvoeren van de query, nu zijn er' $countEnforced 'met de status Enforced'


exit

$count = Get-MsolUser -EnabledFilter EnabledOnly -all | Select-Object DisplayName,UserPrincipalName,@{N="MFAStatus"; E={ if( $_.StrongAuthenticationRequirements.State -ne $null){ $_.StrongAuthenticationRequirements.State} else { "Disabled"}}} | Export-Csv C:\Users\bas.berkhout\Downloads\Usersenabled.csv -NoTypeInformation


$count.Count
