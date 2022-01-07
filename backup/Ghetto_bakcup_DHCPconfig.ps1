$date = Get-Date -format 'dd-MM-yyyy-HHmm'
$CurrentDate = Get-Date
$BackupLocal = 'c:\backup\'
$WeekPath = $BackupLocal +'week'
$backupRemote = '\\****.localIT\Backup_DHCPServers'
$LocalBackupsToKeep = '-30'
$RemoteRetention = '-60' #Retention to keep on the remote storage location 
$fileNameWeek =$BackupLocal+ $date + "-WEEK-backup-dc-lnd01.zip"
$DHCPServers = '****.****.local', '*******.local'
$LocalDelete = $CurrentDate.AddDays($LocalBackupsToKeep) 
$eventSrcName = *** #Source name to find back in the event log.

New-EventLog -LogName Application -Source $eventSrcName -ErrorAction SilentlyContinue
Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 100 -EntryType Information -Message "Starting backup script"
try {
    foreach ($Server in $DHCPServers){
        $ExportFile = $BackupLocal + $date +'-'+ $Server + '-DHCP-Backup.xml'
        Export-DhcpServer -ComputerName $Server -file $ExportFile -Force
        Clear-Variable ExportFile
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 101 -EntryType Information -Message "DHCP setting from $Server exported to $BackupLocal"
    }
}
catch {
    Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 101 -EntryType Error -Message "Export for  $Server failed"
}
Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 103 -EntryType Information -Message "write file to external system incl. weekly backups"
$dayoftheweek = Get-date -Format 'dddd'
$WeekBack = '-7'
$WeekToArchive = $CurrentDate.AddDays($WeekBack) 

If (($dayoftheweek -eq "Zondag") -or ($dayoftheweek -eq "Sunday")) {
    Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 103 -EntryType Information -Message 'It Sunday, time for a weekly backup.'

      try {
        New-Item -ItemType Directory $WeekPath -Force

        Get-ChildItem $BackupLocal | Where-Object {( $_.LastWriteTime -ge $WeekToArchive ) -and ( $_.name -notlike "*WEEK*")} | copy-item -Destination $WeekPath -Force
        Compress-Archive -Path $WeekPath -DestinationPath $fileNameWeek  -CompressionLevel Optimal -Force
        Start-Sleep -Seconds 5  
        Remove-Item -Recurse $WeekPath -Force
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 103 -EntryType Information -Message 'Week backup created, Name $DestinationWeek'
      }
      catch {
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 103 -EntryType Error -Message 'Week backup Failed'
      }

      try {
        net use x: $backupRemote
        Start-Sleep -Seconds 2
        Copy-Item $BackupLocal 'X:\' -Recurse -Force
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Files copied to Z drive'  
      }
      catch {
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Error -Message 'Failed to files copied to Z drive'   
      }

      $RemoteDelete = $CurrentDate.AddDays($RemoteRetention)
      Get-ChildItem X:\ | Where-Object {( $_.LastWriteTime -lt $RemoteDelete ) -and ( $_.name -notlike "*WEEK*")} | Remove-Item -Force
      Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Executed retention policy on remote server'  

      net use x: /Delete
      Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Disconneded the Network drive'  

}
else {
    Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 103 -EntryType Information -Message 'No sunday, just a only off side sync'
    try {
        net use x: $backupRemote
        Start-Sleep -Seconds 2
        Copy-Item $BackupLocal 'X:\' -Recurse -Force
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Files copied to Z drive'  
      }
      catch {
        Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Error -Message 'Failed to files copied to Z drive'   
      }

      $RemoteDelete = $CurrentDate.AddDays($RemoteRetention)
      Get-ChildItem X:\ | Where-Object {( $_.LastWriteTime -lt $RemoteDelete ) -and ( $_.name -notlike "*WEEK*")} | Remove-Item -Force
      Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Executed retention policy on remote server'  

     net use x: /Delete
     Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 104 -EntryType Information -Message 'Disconneded the Network drive'  
}

#cleanup local backup folder.
Get-ChildItem $BackupLocal | Where-Object ( $_.LastWriteTime -lt $LocalDelete )  | Remove-Item -Force
Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 105 -EntryType Information -Message 'remove older localbackup files'  
Write-EventLog -LogName Application -Source "$eventSrcName" -EventId 110 -EntryType Information -Message 'All done, exit'  

Exit
##script signature.