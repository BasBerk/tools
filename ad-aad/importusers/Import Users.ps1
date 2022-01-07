$cred = (Get-Credential)
Enter-PSSession -ComputerName "192.168.192.53" -Credential $cred
$Users = Import-CSV -path "c:\Users\admin.basb\Documents\importlist.csv" -delimiter ';'
foreach ($user in $Users ) {
   New-ADUser -Name $User.Name -DisplayName $User.Name -GivenName $user.GivenName`
    -SurName $User.Surname -SAMAccountName $User.SAMAccountName -Enabled $True -ChangePasswordAtLogon $True -PasswordNeverExpires $False `
    -Path $user.path-UserPrincipalName $user.userPrincipalName -AccountPassword (ConvertTo-SecureString -AsPlainText -Force -String $user.pw ) -Verbose -ErrorAction SilentlyContinue
   }


Invoke-Command -ComputerName cor-dc02.corendon.local -Credential $cred -ScriptBlock { $path}
