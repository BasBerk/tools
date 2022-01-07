$MacAddress = $null
$HWaddress = $null
$HWvendor = $null
$MacAddresses = $null

$URLmacvendor = "http://api.macvendors.com/"
$MacAddresses = Import-Csv ".\macadresses.csv" -Delimiter ";"

$n = 0

Foreach ($MacAddress in $MacAddresses) {
    $n = $n + 1
    $HWaddress = $MacAddress.HWaddress
    $HWURL = $URLmacvendor+"/"+$HWaddress
    $HWResult = try { $response = Invoke-WebRequest $HWURL } catch { $_.Exception.Response.StatusCode.Value__ }
    if ($HWResult -eq "404") {$HWvendor = "Vendor not found"}
    else {$HWvendor = $response}
    Write-Host $n ". IP:" $MacAddress.Address "and MAC:" $HWaddress "Vendor is:" $HWvendor
    }
