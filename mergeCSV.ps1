#This merges csv files based on matching columns
#Merge-Csv -path "exportusers.csv", 'MFA batch list .csv' -id  SamAccountName -Delimiter ';' |Export-Csv -Encoding UTF8 -NoTypeInformation -Path "Exportnew.csv" -Delimiter ';' #merge de csv met uid Username


function Merge-Csv {
    [CmdletBinding(
        DefaultParameterSetName = 'Files'
    )]
    param(
        # Shared ID column(s)/header(s).
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]] $Identity,
        
        # CSV files to process.
        [Parameter(ParameterSetName = 'Files', Mandatory = $true)]
        [ValidateScript({ Test-Path $_ -PathType Leaf })]
        [String[]] $Path,
        
        # Custom PowerShell objects to process.
        [Parameter(ParameterSetName = 'Objects', Mandatory = $true)]
        [PSObject[]] $InputObject,
        
        # Optional delimiter that's used if you pass file paths (default is a comma).
        [Parameter(ParameterSetName = 'Files')]
        [String] $Delimiter = ',',

        # Optional multi-ID column string separator (default "#Merge-Csv-Separator#").
        [String] $Separator = '#Merge-Csv-Separator#',
        
        # Allow duplicate entries (IDs).
        [Switch] $AllowDuplicates,
        
        # Include alias properties.
        [Switch] $IncludeAliasProperty)

    [String[]] $PropertyTypes = @()
    if ($IncludeAliasProperty) {
        $PropertyTypes = @("NoteProperty", "AliasProperty")
    }
    else {
        $PropertyTypes = @("NoteProperty")
    }
    [PSObject[]] $CsvObjects = @()
    if ($PSCmdlet.ParameterSetName -eq 'Files') {
        $CsvObjects = foreach ($File in $Path) {
            , @(Import-Csv -Delimiter $Delimiter -Path $File)
        }
    }
    else {
        $CsvObjects = $InputObject
    }
    $Headers = @()
    foreach ($Csv in $CsvObjects) {
        $Headers += , @($Csv | Get-Member -MemberType $PropertyTypes | Select-Object -ExpandProperty Name)
    }
    $Counter = 0
    foreach ($h in $Headers) {
        $Counter++
        foreach ($Column in $Identity) {
            if ($h -notcontains $Column) {
                Write-Error "Headers in object/file $Counter don't include $Column. Exiting."
                return
            }
        }
    }
    $HeadersFlatNoShared = @($Headers | ForEach-Object { $_ } | Where-Object { $Identity -notcontains $_ })
    if ($HeadersFlatNoShared.Count -ne @($HeadersFlatNoShared | Sort-Object -Unique).Count) {
        Write-Error "Some headers are shared. Are you just looking for '@(ipcsv csv1) + @(ipcsv csv2) | Export-Csv ...'?`nTo remove duplicate (between the files to merge) headers from a CSV file, Import-Csv it, pass it to Select-Object, and omit the duplicate header(s)/column(s).`nExiting."
        return
    }
    $SharedColumnHashes = @()
    $SharedColumnCount = $Identity.Count
    $Counter = 0
    foreach ($Csv in $CsvObjects) {
        $SharedColumnHashes += @{}
        $Csv | ForEach-Object {
            $CurrentID = $(for ($i = 0; $i -lt $SharedColumnCount; $i++) {
                    $_ | Select-Object -ExpandProperty $Identity[$i] -EA SilentlyContinue
                }) -join $Separator
            if (-not $SharedColumnHashes[$Counter].ContainsKey($CurrentID)) {
                $SharedColumnHashes[$Counter].Add($CurrentID, @($_ | Select-Object -Property $Headers[$Counter]))
            }
            else {
                if ($AllowDuplicates) {
                    $SharedColumnHashes[$Counter].$CurrentID += $_ | Select-Object -Property $Headers[$Counter]
                }
                else {
                    Write-Warning ("Duplicate identifying (shared column(s) ID) entry found in CSV data/file $($Counter+1): " + ($CurrentID -replace [regex]::Escape($Separator), ', '))
                }
            }
        }
        $Counter++
    }
    $Result = @{}
    $NotFound = @{}
    foreach ($Counter in 0..($SharedColumnHashes.Count - 1)) {
        foreach ($InnerCounter in (0..($SharedColumnHashes.Count - 1) | Where-Object { $_ -ne $Counter })) {
            foreach ($Key in $SharedColumnHashes[$Counter].Keys) {
                Write-Verbose "Key: $Key, Counter: $Counter, InnerCounter: $InnerCounter"
                $Obj = New-Object -TypeName PSObject
                if ($SharedColumnHashes[$InnerCounter].ContainsKey($Key)) {
                    foreach ($Header in $Headers[$InnerCounter] | Where-Object { $Identity -notcontains $_ }) {
                        Add-Member -InputObject $Obj -MemberType NoteProperty -Name $Header -Value ($SharedColumnHashes[$InnerCounter].$Key | Select-Object $Header)
                    }
                }
                else {
                    foreach ($Header in $Headers[$Counter]) {
                        if ($Identity -notcontains $Header) {
                            Add-Member -InputObject $Obj -MemberType NoteProperty -Name $Header -Value ($SharedColumnHashes[$Counter].$Key | Select-Object $Header)
                        }
                    }
                    if (-not $NotFound.ContainsKey($Key)) {
                        $NotFound.Add($Key, @($Counter))
                    }
                    else {
                        $NotFound[$Key] += $Counter
                    }
                }
                if (-not $Result.ContainsKey($Key)) {
                    $Result.$Key = $Obj
                }
                else {
                    foreach ($Property in @($Obj | Get-Member -MemberType $PropertyTypes | Select-Object -ExpandProperty Name)) {
                        if (-not ($Result.$Key | Get-Member -MemberType $PropertyTypes -Name $Property)) {
                            Add-Member -InputObject $Result.$Key -MemberType NoteProperty -Name $Property -Value $Obj.$Property #-EA SilentlyContinue
                        }
                    }
                }
                
            }
        }
    }
    if ($NotFound) {
        foreach ($Key in $NotFound.Keys) {
            Write-Warning "Identifying column entry '$($Key -replace [regex]::Escape($Separator), ', ')' was not found in all CSV data objects/files. Found in object/file no.: $(
                if ($NotFound.$Key) { ($NotFound.$Key | ForEach-Object { ([int]$_)+1 } | Sort-Object -Unique) -join ', '}
                elseif ($CsvObjects.Count -eq 2) { '1' }
                else { 'none' }
                )"
        }
    }
    #$Global:Result = $Result
    $Counter = 0
    [hashtable[]] $SharedHeadersNoDuplicate = $Identity | ForEach-Object {
        @{n = "$($Identity[$Counter])"; e = [scriptblock]::Create("(`$_.Name -split ([regex]::Escape('$Separator')))[$Counter]") }
        $Counter++
    }
    [hashtable[]] $HeaderPropertiesNoDuplicate = $HeadersFlatNoShared | ForEach-Object {
        @{n = $_.ToString(); e = [scriptblock]::Create("`$_.Value.'$_' | Select -ExpandProperty '$_'") }
    }
    [int] $HeadersFlatNoSharedCount = $HeadersFlatNoShared.Count
    # Return results.
    if (-not $AllowDuplicates) {
        $Result.GetEnumerator() | Select-Object -Property ($SharedHeadersNoDuplicate + $HeaderPropertiesNoDuplicate)
    }
    else {
        $Result.GetEnumerator() | ForEach-Object {
            # Latching on support for duplicate objects. Insanely inefficient.
            # Variable for the count of duplicates we find. Initialize to 1 for each array of PSobjects for each ID.
            $MaxDuplicateCount = 1
            foreach ($Title in $_.Value | Get-Member -MemberType $PropertyTypes | Select-Object -ExpandProperty Name) {
                $Count = @($_.Value.$Title).Count
                # find max count for this instance (if at all higher than 1)
                # duplicates are processed in the order they occur
                if ($MaxDuplicateCount -lt $Count) {
                    $MaxDuplicateCount = $Count
                }
            }
            Write-Verbose "Max duplicate count: $MaxDuplicateCount"
            foreach ($i in 0..($MaxDuplicateCount - 1)) {
                # Add ID(s) once to each object.
                $Obj = $null
                $Obj = New-Object -TypeName PSObject
                $IDSplitCounter = 0
                foreach ($TempID in $Identity) {
                    Add-Member -InputObject $Obj -MemberType NoteProperty -Name $TempID -Value @($_.Name -split [Regex]::Escape($Separator))[$IDSplitCounter]
                    ++$IDSplitCounter
                }
                foreach ($NumHeader in 0..($HeadersFlatNoSharedCount - 1)) {
                    try {
                        $Value = ($_.Value.($HeadersFlatNoShared[$NumHeader]))[$i] | Select-Object -ExpandProperty $HeadersFlatNoShared[$NumHeader]
                    }
                    catch {
                        Write-Verbose "Caught out of bounds in array."
                        $Value = '' #| Select-Object -Property $HeadersFlatNoShared[$NumHeader]
                    }
                    Add-Member -InputObject $Obj -MemberType NoteProperty -Name $HeadersFlatNoShared[$NumHeader] -Value $Value
                }
                $Obj | Select-Object -Property ($Identity + $HeadersFlatNoShared)
            }
        }
    }
}
#Export-ModuleMember -Function Merge-Csv

