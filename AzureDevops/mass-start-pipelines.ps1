[CmdletBinding]
Param
(
    [Parameter(Mandatory = $true)]
    [string]
    $PAT, # Personal Access Token

    [Parameter(Mandatory = $true)]
    [string]
    $AzureDevOpsProjectURL, # https://vsrm.dev.azure.com/{organization}/{project}
  
    [Parameter(Mandatory = $false)]
    [string]
    $Folder,
    [Parameter(Mandatory = $false)]
    [string]
    $Branch
)

$Branch = 'bb/switch-to-test-pool'

$folder = "*Automation.Wiki\Productie*"

# Base64-encodes the Personal Access Token (PAT) appropriately
# This is required to pass PAT through HTTP header

$script:Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $PAT)))

#function to list all pipelines in a specific project and folder
function get-pipelinesIds {
    [CmdletBinding()]
    param (
        $folder
    )
    
 
    
    $raw = Invoke-RestMethod -Uri 'https://dev.azure.com/weareinspark/Managed%20Services%20-%20Infra/_apis/pipelines' -Method GET -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) }
    #filter on folder 
    $result = $raw.value | Where-Object { $_.folder -like $folder } | Select-Object -ExpandProperty id
    return $result
}


$pipelineIds = get-pipelinesIds -folder $folder

#function to start a pipeline with a specific id
function start-pipeline {
    param (
        $id,
        $Branch 
    )
    $jsonobj = [PsCustomObject] @{
    
        resources = [PsCustomObject] @{
            repositories = [PsCustomObject] @{
                self = [PsCustomObject] @{
                    repository = [PsCustomObject] @{
                        type = "azureReposGit"
                    }
                    refName    = "refs/heads/$Branch"
               
                }
            }
        }
    }
    $json = $jsonobj | ConvertTo-Json -Depth 20
    
    "starting pipeline with id: {0}" -f $id | Write-Host
    $uri = "https://dev.azure.com/weareinspark/Managed%20Services%20-%20Infra/_apis/pipelines/{0}/runs?api-version=7.1-preview.1" -f $id
    Invoke-RestMethod -Uri $uri -Method POST -Headers @{Authorization = ("Basic {0}" -f $Base64AuthInfo) } -ContentType 'application/json' -Body $json
}

#start the function start-pipeline for each pipeline id in parralel
foreach ($id in $pipelineIds) {
    start-pipeline -id $id -Branch $Branch
}

start-pipeline -id 1572 -Branch $Branch


$selection = @(559,1317,582)

foreach ($id in $selection) {
    start-pipeline -id $id -Branch $Branch
}