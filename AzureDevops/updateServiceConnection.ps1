<#
.Description
   This Scipt can be used to mass update task in all you release pipelines. In this case the service connection
.Example
    For listing all release pipeline:
    \updateServiceConnection.ps1 -PAT "NoTaReAlPaT" -AzureDevOpsProjectURL "https://vsrm.dev.azure.com/{organization}/{project}" -oldServiceConnection "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -newServiceConnection  "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -ListPipelineIDs 1
    For updating a specific pipeline:
    .\updateServiceConnection.ps1 -PAT "NoTaReAlPaT" -AzureDevOpsProjectURL "https://vsrm.dev.azure.com/{organization}/{project}" -oldServiceConnection "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -newServiceConnection  "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" PipelineIDs 1,2,3,45 
    For updating all release pipelines in one go.
    .\updateServiceConnection.ps1 -PAT "NoTaReAlPaT" -AzureDevOpsProjectURL "https://vsrm.dev.azure.com/{organization}/{project}" -oldServiceConnection "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -newServiceConnection  "000000-3xxxx-xxxx-xxxx-xxxxx1ca2" -UpdateAllPipelines 1

#>

[CmdletBinding(DefaultParameterSetName = "write")]
Param
(
  [Parameter(Mandatory = $true,
    ParameterSetName = "write" )]
  [Parameter(Mandatory = $true,
    ParameterSetName = "read" )]
  $PAT, # Personal Access Token

  [Parameter(Mandatory = $true,
    ParameterSetName = "write" )]
  [Parameter(Mandatory = $true,
    ParameterSetName = "read" )]
  $AzureDevOpsProjectURL, # https://vsrm.dev.azure.com/{organization}/{project}
  
  [Parameter(Mandatory = $true,
    ParameterSetName = "write" )]
  $oldServiceConnection,

  [Parameter(Mandatory = $true,
    ParameterSetName = "write")]
  $newServiceConnection,

  [Parameter(Mandatory = $true,
    ParameterSetName = "read")]
  [bool]
  $ListPipelineIDs,

  [Parameter(Mandatory = $false,
    ParameterSetName = "write")]
  $PipelineIDs,

  [Parameter(Mandatory = $false,
    ParameterSetName = "write")]
  [bool]
  $UpdateAllPipelines
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

function ListPipelines {
  $pipeLineInfo = @()
  for ( $i = 0; $i -ne $GetDefinitionsUriResponse.count + 1; $i++) {
    $Name = $GetDefinitionsUriResponse.value[$i].name
    $PipelineID = $GetDefinitionsUriResponse.value[$i].id
        
    $pipeLineInfo += New-Object -TypeName psobject -Property @{ID = "$PipelineID"; Name = "$name" }
  }
  return $pipeLineInfo | sort Name
}

function updateTasks {
  param (
    $DefinitionID
  )
  [uri] $script:GetDefinitionURI = "$AzureDevOpsProjectURL/_apis/release/definitions/$DefinitionID"
  $GetDefinitionResponse = Invoke-RestMethod -Uri $GetDefinitionURI -Method GET -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) }
  $allTasks = $GetDefinitionResponse.environments.deployPhases.workflowTasks | where { ($_.inputs.ConnectedServiceNameARM -eq $oldServiceConnection) -or ($_.inputs.ConnectedServiceName -eq $oldServiceConnection) }
    
  # Loop through each relevant task 
  ForEach ($Task in $allTasks ) {
    write-host -ForegroundColor green "start with $task."
    #Powershell tasks store the servce connection in connectedServiceNameARM, ARM deploymant task inconnectedServiceName
    if ($task.inputs.ConnectedServiceNameARM -eq $oldServiceConnection) {
      $task.inputs.ConnectedServiceNameARM = $newServiceConnection
    }
    elseif ($task.inputs.ConnectedServiceName -eq $oldServiceConnection) {
      $task.inputs.ConnectedServiceName = $newServiceConnection
    }
    else {
      write-host "Service Connection cannot be changed. "
    }
  }
  # Convert response to JSON to be used in Put below
  $Definition = $GetDefinitionResponse | ConvertTo-Json -Depth 100

  # Use updated response to update definition.
  # Note: Release Definition ID is not needed in URI for PUT
  # version is the latest stable version at this moment.
  $script:UpdateDefinitionURI = "$AzureDevOpsProjectURL/_apis/release/definitions?api-version=7.1-preview"
  Invoke-RestMethod -Uri $UpdateDefinitionURI -Method Put -ContentType application/json -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) } -Body $Definition
}

function UpdateSelectedPipelines {
  param (
    $PipelineIDs
  )
  ForEach ($DefinitionID in $PipelineIDs) {
    updateTasks -DefinitionID $DefinitionID
  }
}

UpdateSelectedPipelines -PipelineIDs 17
function UpdateAllPipelines {
  ForEach ($DefinitionID in $DefinitionIDs) {
    updateTasks -DefinitionID $DefinitionID
  }
}

if ($ListPipelineIDs -eq 1 ) {
  ListPipelines
}

if ($UpdateAllPipelines -eq 1) {
  if ($PipelineIDs -ne $null ) {
    Write-Error "You want to run all pipelines, but also provide an ID `n Remove the flag UpdateAllPipelines or remove the Pipelines ids."
  }
  else {
    Write-Host -ForegroundColor green "Updating all pipelines."
    UpdateAllPipelines 
    Write-Host -ForegroundColor green "Finished updating all pipelines."
  }
}

if ($PipelineIDs -ne $null) {
  Write-Host -ForegroundColor green "Updating the selected Pipelines Ids"
  UpdateSelectedPipelines -PipelineIDs $PipelineIDs
  Write-Host -ForegroundColor green "Finished with the selected Pipelines Ids"
}