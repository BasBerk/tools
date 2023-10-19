# Import the VSTeam module
#script om eenmalig de pipeline aan te maken

# Set the DevOps organization URL and PAT token
$orgUrl = "https://dev.azure.com/weareinspark/"

function GetRepositoryId {
    param (
        [string] $organization,
        [string] $project,
        [string] $pat,
        [string] $repositoryName
    )

    $script:User = "" # Not needed when using PAT, can be set to anything
    $script:Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $PAT)))
    $AzureDevOpsProjectURL = "https://dev.azure.com/$organization"
    [uri] $script:GetRepositoryIdUri = "$AzureDevOpsProjectURL/$project/_apis/git/repositories?api-version=7.2-preview.1"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    # add the authorization header
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Basic $Base64AuthInfo")
    $body = $body | ConvertTo-Json -Depth 100

    $reponse = Invoke-RestMethod -Uri $GetRepositoryIdUri -Headers $headers -Method Get
    $response = $reponse.value | Where-Object { $_.name -eq $repositoryName } | Select-Object -ExpandProperty id

    return $response
}

GetRepositoryId -organization 'weareinspark' -repositoryName 'Automation.Billing' -project 'Managed Services - Infra' -pat $pat

function createPipeline {
    param (
        [string] $organization,
        [string] $project,
        [string] $pat,
        [string] $repositoryName,
        [string] $pipelineName,
        [string] $yamlPath,
        [string] $folderPath
    )

    $script:User = "" # Not needed when using PAT, can be set to anything
    $script:Base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $User, $PAT)))

    $AzureDevOpsProjectURL = "https://dev.azure.com/$organization"

    #Get Repository ID
    [uri] $script:createPipelineUri = "$AzureDevOpsProjectURL/$project/_apis/pipelines?api-version=7.2-preview.1"

    # Read the YAML file contents
    $yamlContent = Get-Content $yamlPath -Raw

    # Set the request body
    $body = [PSCustomObject]@{
        folder    = $folderPath
        name          = $pipelineName
        configuration = @{
            type       = "yaml"
            folder     = $folderPath
            path       = $yamlPath
            repository = @{
                id   = (GetRepositoryId -organization $organization -repositoryName $repositoryName -project $project -pat $pat)
                name = $repositoryName
                type = "azureReposGit"
            }
            content    = $yamlContent
        }
    }

    # Convert the body to JSON
    $jsonBody = $body | ConvertTo-Json -Depth 100

    # Set the request headers
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    # add the authorization header
    $headers.Add("Content-Type", "application/json")
    $headers.Add("Authorization", "Basic $Base64AuthInfo")

    # Set the request URL
    $url = "$orgUrl/$projectName/_apis/pipelines?api-version=7.2-preview.1"

    # Send the request
    $response = Invoke-RestMethod -Uri $createPipelineUri -Method Post -Headers $headers -Body $jsonBody

    return $response
}


function Get-YamlFiles {
    param (
        [string] $path,
        [string] $folderName = "",
        [string[]] $excludeFolders = @()
    )

    # Get the files in the current folder
    $files = Get-ChildItem $path -File

    # Loop over the files and find YAML/YML files
    foreach ($file in $files) {

        if ($file.Extension -eq ".yaml" -or $file.Extension -eq ".yml") {
            # Store the path, full file name, folder name, and file name without extension
            $filePath = $file.FullName
            $fileName = $file.Name
            $folder = $folderName
            $fileNameWithoutExtension = $file.BaseName

            # Output the results
            [PSCustomObject]@{
                FilePath                 = $filePath
                FileName                 = $fileName
                Folder                   = $folder
                FileNameWithoutExtension = $fileNameWithoutExtension
                relativePath             = "./pipelines/customers/" + $folder + "/" + $fileName
            }
        }
    }

    # Get the subfolders in the current folder
    $folders = Get-ChildItem $path -Directory

    # Loop over the subfolders and recursively call the function
    foreach ($folder in $folders) {
        if ($folder.Name -notin $excludeFolders) {
            Get-YamlFiles -path $folder.FullName -folderName $folder.Name -excludeFolders $excludeFolders
        }
    }
}

# Call the function with the root folder path
Get-YamlFiles -path ./pipelines -excludeFolders "templates", "development", "template" 


Get-YamlFiles -path ./pipelines -excludeFolders "templates", "development", "template" | foreach {
    createPipeline -organization 'weareinspark' -repositoryName 'Automation.Billing' -project 'Managed Services - Infra' -pat $pat -folderPath '/Automation.Billing/PROD' -pipelineName $_.folder -yamlPath $_.relativePath
}

createPipeline -organization 'weareinspark' -repositoryName 'Automation.Billing' -project 'Managed Services - Infra' -pat $pat -folderPath '/Automation.Billing/PROD' -pipelineName 'bas-test2' -yamlPath "./pipelines/development/ccc_test.yml" 
