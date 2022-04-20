<#
.Description
   This Scipt can be used to mass update task in all you release pipelines. In this case the service connection
.Example
    .\updateServiceConnection.ps1 -PAT "NoTaReAlPaT" -AzureDevOpsProjectURL "https://vsrm.dev.azure.com/{organization}/{project}" -oldServiceConnection "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -newServiceConnection  "000000-3xxxx-xxxx-xxxx-xxxxx1ca2"
#>

[CmdletBinding()]
Param
(
    [Parameter(Mandatory = $true)]
    $PAT, # Personal Access Token
    [Parameter(Mandatory = $true)]
    $AzureDevOpsProjectURL, # https://vsrm.dev.azure.com/{organization}/{project}
    [Parameter(Mandatory = $true)]
    $oldServiceConnection,
    [Parameter(Mandatory = $true)]
    $newServiceConnection
)

# Base64-encodes the Personal Access Token (PAT) appropriately
# This is required to pass PAT through HTTP header
$script:User = "" # Not needed when using PAT, can be set to anything
$script:Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $PAT)))

# Get list of all release definitions (pipelines)
[uri] $script:GetDefinitionsUri = "$AzureDevOpsProjectURL/_apis/Release/definitions"

# Invoke the REST call and capture the response
$GetDefinitionsUriResponse = Invoke-RestMethod -Uri $GetDefinitionsURI -Method Get -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) }
$DefinitionIDs = $GetDefinitionsUriResponse.value.id

ForEach ($DefinitionID in $DefinitionIDs) {
    [uri] $script:GetDefinitionURI = "$AzureDevOpsProjectURL/_apis/release/definitions/$DefinitionID"
    $GetDefinitionResponse = Invoke-RestMethod -Uri $GetDefinitionURI -Method GET -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) }

    # Navigate to the tasks
    $allTasks = $GetDefinitionResponse.environments.deployPhases.workflowTasks 
    
    $inputs = $allTasks.inputs 
    # skip tasks that are already in the desired state.
    $tasks = $inputs | where-object { ($_.ConnectedServiceNameARM -eq $oldServiceConnection) -or ($_.ConnectedServiceName -eq $oldServiceConnection) }
    if ($tasks -eq $null) {
        continue
    }
    # Loop through each relevant task 
    ForEach ($Task in $tasks) {

        #Powershell tasks store the servce connection in connectedServiceNameARM, ARM deploymant task inconnectedServiceName
        if ($task.PSobject.Properties.name -match "connectedServiceNameARM") {
            $Task.connectedServiceNameARM = $newServiceConnection
        }
        elseif ($task.PSobject.Properties.name -match "ConnectedServiceName") {
            $Task.ConnectedServiceName = $newServiceConnection
        }
        else {
            write-host "Service Connection cannot be changed. "
        }

        # Convert response to JSON to be used in Put below
        $Definition = $GetDefinitionResponse | ConvertTo-Json -Depth 100

        # Use updated response to update definition.
        # Note: Release Definition ID is not needed in URI for PUT
        # version is the latest stable version at this moment.
        $script:UpdateDefinitionURI = "$AzureDevOpsProjectURL/_apis/release/definitions?api-version=7.0"
        Invoke-RestMethod -Uri $UpdateDefinitionURI -Method Put -ContentType application/json -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) } -Body $Definition
    }
}