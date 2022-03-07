<# 
This script loops though all your subscriptions and checks for failes backups.
If it finds something it will double check if there is an successfull isntance for that item. of not it will start a backup.
#>

$vmsstarted = @()
#loop door subs
$subs = @(Get-AzSubscription)

$rmLockVmRg = 'true'
$rmLockRsv = 'true'
function removeLock {
    param (
        $rg
    )

    Get-AzResourceLock -ResourceGroupName $rg -AtScope | Remove-AzResourceLock -Force
}

ForEach ($sub  in $subs) {
    try {
        Set-AzContext -SubscriptionName $sub.Name
    }
    catch {
        $_
        Write-Error "problem with entering subscription $sub.name"
    }
    $recoverySericeVaults = @(Get-AzRecoveryServicesVault)

    foreach ($rsv in $recoverySericeVaults) {
        $failedList = @()
        $completed = @()
        $toStart = @()
        $vault = Get-AzRecoveryServicesVault -Name $rsv.Name -ResourceGroupName $rsv.ResourceGroupName
        write-host -ForegroundColor green "start loading status Recovery service vault: "$vault.Name""
        write-host "Load all job of the last 24h"
        $list = @(Get-AzRecoveryServicesBackupJob  -VaultId $vault.ID -from $date.AddHours(-24).ToUniversalTime() | ? Operation -eq 'Backup' )  
        foreach ($item in $list ) {
            if ($item.status -eq 'Failed') {
                $failedList += $item
            }
            else {
                $completed += $item
            } 
        }

        Write-host -ForegroundColor green 'Filter list with vms that only have a failed backup'
        foreach ($i in $list ) {
            if ($i.WorkloadName -notin $completed.WorkloadName ) {
                $toStart += $i
            }
            else {
                write-host -ForegroundColor red ""$i.WorkloadName"has an succesfull or running job already"
            }
        }

        write-host -ForegroundColor green "Remove duplicates"
        $cleanList = $(foreach ($x in $toStart.WorkloadName) {
                $x
            }) | sort | Get-Unique
        
        write-host -ForegroundColor green  "The following "$cleanList.Count" vms need to be backuped"
        foreach ($backupItem in $cleanList) {
            if ($rmLockVmRg -eq "true") {
                $rg = Get-AzVM -Name test-weuwappa01 | select -ExpandProperty ResourceGroupName
               removeLock -rg $rg
            }
            if ($rmLockRsv -eq 'true'){
                removeLock -rg $vault.ResourceGroupName
            }
            
            
            write-host -ForegroundColor Yellow  "start backup for $backupItem"
            $NamedContainer = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -Status Registered -FriendlyName $backupItem -VaultId $vault.ID
            $Item = Get-AzRecoveryServicesBackupItem -Container $NamedContainer -WorkloadType AzureVM -VaultId $vault.ID
            Backup-AzRecoveryServicesBackupItem -Item $Item -VaultId $vault.ID 
            $vmsstarted += $item
        }
    }
}
$vmsstarted.Count
