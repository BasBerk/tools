###############################################################################
##Script:           IIS log rotation
##
##Description:      Cleans up the IIS logfiles older than XX days
##Created by:       Bas Berkhout - 
##Creation Date:    24-4-2019
##Instructions:     Schedule script to run at the desired interval, it will check for files older than xx days and remove them
##
## Version:          1.0
## 
###############################################################################
$limit = (Get-Date).AddDays(-60)
$path = 'C:\inetpub\logs\LogFiles\W3SVC1\'
$path1 = 'C:\inetpub\logs\LogFiles\W3SVC2\'
$path2 = 'C:\inetpub\logs\LogFiles\W3SVC3\'
$path3 = 'C:\inetpub\logs\LogFiles\W3SVC4\'

 
# Delete files older than the $limit.
Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $path1 -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $path2 -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force
Get-ChildItem -Path $path3 -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Remove-Item -Force
