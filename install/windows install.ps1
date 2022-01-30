$applications = @("Microsoft Visual Studio Code","Git.Git", "Microsoft.Bicep","Microsoft.AzureStorageExplorer", "Microsoft.AzureFunctionsCoreTools","Microsoft.PowerShell"
 "JanDeDobbeleer.OhMyPosh", "Debian.Debian", "Canonical.Ubuntu.2004", "Microsoft Azure CLI", "Nextcloud.NextcloudDesktop", "Obsidian.Obsidian","Bitwarden.Bitwarden"
 "Spotify.Spotify", "Notepad++.Notepad++" ,"Mirantis.Lens" ,"Twilio.Authy")


foreach ($application in $applications){
 winget install --id $application --accept-source-agreements --accept-package-agreements
}

