#Open powershell or windows terminal. CD to where this file is located and run Check-ServiceConnection.ps1
[CmdletBinding()]
param(
    [parameter(Mandatory=$true)]
    [string]$orgUrl,

    [parameter(Mandatory=$false)]
    [string[]]$projects,
          
    [parameter(mandatory=$false)]
    [string]$pat               
)


function CheckAll-ReleasePipelines {
    param (
    $orgUrl,    
    $project
    )
    
    $pipelineList = az pipelines release definition list --org  $orgUrl --project $project.name | convertFrom-Json

    if($pipelineList.Length -eq 0)
    {
        Write-Host "No release pipeline found in '$($project.name)'"
    }
    else {            
        Write-Host "$($pipelineList.Length) release pipeline(s) found."        
        $pipelineList.name | ForEach-Object {
            $pipelineName = $_

            Check-ReleasePipeline -orgUrl $orgUrl -project $project -pipelineName $pipelineName
        }
    }
}

function Check-ReleasePipeline {
    param (
    $orgUrl,    
    $project,
    $pipelineName
    )
    
    Write-Host "checking $pipelineName"    
    $pipelineDef = az pipelines release definition show --org $orgUrl --project $project.name --name $pipelineName

    $project.serviceConnections | ForEach-Object {
        $svcConn = $_

        $matchIdStr = "*$($svcConn.id)*"
        Write-Verbose "checking $($svcConn.name); match ID string=$matchIdStr"

        $matchNameStr = "*$($svcConn.name)*"
        Write-Verbose "checking $($svcConn.name); match name string=$matchNameStr"


        if(($pipelineDef -like $matchIdStr) -or ($pipelineDef -like $matchNameStr))
        {
            $svcConn.pipelines +=  $pipelineName
        }  
    }
}

function CheckAll-BuildPipelines {
    param (
    $orgUrl,    
    $project
    )
    
    $pipelineList = az pipelines build definition list --org  $orgUrl --project $project.name | convertFrom-Json

    if($pipelineList.Length -eq 0)
    {
        Write-Host "No build pipeline found in '$($project.name)'"
    }
    else {            
        Write-Host "$($pipelineList.Length) build pipeline(s) found."
        $pipelineList.name | ForEach-Object {
            $pipelineName = $_

            Check-BuildPipeline -orgUrl $orgUrl -project $project  -pipelineName $pipelineName
        }
    }
}
function Check-BuildPipeline {
    param (
    $orgUrl,    
    $project,
    $pipelineName
    )
    
    Write-Host "checking $pipelineName"
    $pipelineDef = az pipelines build definition show --org $orgUrl --project $project.name --name $pipelineName
    $pipelineJsonDef = $pipelineDef | ConvertFrom-Json

    $hasError = $false

    if($pipelineJsonDef.process.type -eq 1)
    {
        # classic
        # no further action required. everything we need already in the json content.         
        Write-Verbose "$($pipelineJsonDef.name) CLASSIC"
    }
    elseif ($pipelineJsonDef.process.type -eq 2) {
        # yaml
        # we need to get the definition from the yaml file.
        Write-Verbose "$($pipelineJsonDef.name) YAML"     
               
        #$repoName = $pipelineJsonDef.repository.name
        $repoUrl = $pipelineJsonDef.repository.url
        $yamlFile = $pipelineJsonDef.process.yamlFilename
        $tmpRepoName = "tmpRepo"
        
        Write-Verbose "YAML file: $yamlFile"

        # clone the repo to download the yaml file.
        # assume the user already authenticated with the repo. Otherwise it will fail.
        git clone -n $repoUrl $tmpRepoName --depth 1 *>$null
        Push-Location $tmpRepoName
        git checkout HEAD $yamlFile *>$null
        $pipelineDef = Get-Content $yamlFile
        Pop-Location
        Remove-item  -Force -Recurse $tmpRepoName
        Write-Verbose "$pipelineDef"           
    }
    else {
        $hasError = $true
        Write-Warning "Unknown pipeline type $($pipelineJsonDef.name)"
    }


    if($hasError -eq $false)
    {
        $project.serviceConnections | ForEach-Object {
            $svcConn = $_

            $matchIdStr = "*$($svcConn.id)*"
            Write-Verbose "checking $($svcConn.name); match ID string=$matchIdStr"

            $matchNameStr = "*$($svcConn.name)*"
            Write-Verbose "checking $($svcConn.name); match name string=$matchNameStr"

            if(($pipelineDef -like $matchIdStr) -or ($pipelineDef -like $matchNameStr))
            {
                $svcConn.pipelines +=  $pipelineName
            }       
        }
    }
}


if($null -ne $pat)
{
    # Set the PAT needed to authenticate to Azure DevOps
    $env:AZURE_DEVOPS_EXT_PAT = $pat
}

if($null -eq $projects)
{
    # No project name given. So we retrieve all projects in the given Organization.
    $prjlist = az devops project list --org $orgUrl |  convertFrom-Json
    $projects = $prjlist.value.name
}

Write-Host "$($projects.length) projects found."

$output = @()

foreach ($proj in $projects) {
    Write-Host "checking in project : $proj"

    $projObject = [PSCustomObject]@{
        name =  $proj
        serviceConnections = @()
    }

    $output += $projObject

    # Get all service connection in project
    $svcConnList =  az devops service-endpoint list --org $orgUrl --project $proj | convertFrom-Json

    # add service connections to the project.
    $svcConnList | ForEach-Object {
        $svcConn = $_
        $svcConnCO = [PSCustomObject]@{
            name =  $svcConn.name
            id = $svcConn.id
            pipelines = @()
        }

        $projObject.serviceConnections += $svcConnCO
    }

    CheckAll-BuildPipelines -orgUrl $orgUrl -project $projObject 
    CheckAll-ReleasePipelines -orgUrl $orgUrl -project $projObject 
}

$output 