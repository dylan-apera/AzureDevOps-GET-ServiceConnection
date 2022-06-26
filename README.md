# Azure DevOps Administration: Service Connection Management
This project was established based on one key component, how do we manage the number of Azure DevOps service connections within a tenant. This Powershell script is the first step to understanding what we have in place within our Azure DevOps tenant, and will be a good first step to tidying your AzDO environment and hardening your security posture. 

## What you need
1. You will need to install windows terminal or powershell to run this script. 
- [Windows Powershell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.2)
- [Windows Terminal](https://apps.microsoft.com/store/detail/windows-terminal/9N0DX20HK701?hl=en-us&gl=US)

2. In your tool of choice navigate to the folder the script is located in. 
- Note: run (az login) or (az devops login) to ensure that you are running this on the right tenant. 

3. Run the ./Check-ServiceConn.ps1 in your window. 
4. Input your organisation address, example: https://www.dev.azure.com/<MyOrgName>
5. (Optional): If using az devops login please ensure to provide a Personal Access Token (PAT). Please [see here](https://docs.microsoft.com/en-us/azure/devops/organizations/accounts/use-personal-access-tokens-to-authenticate?view=azure-devops&tabs=Windows) for more info. 
6. Run the script. It may push out a few errors at the beginning but towards the end of it you will see results of service connection, correlating projects/pipelines, owners and history. 



## Disclaimer
Even though I do work for Microsoft this content is not official Microsoft content. This repository was establish to help organisations manage their growing use of Azure DevOps and to make the lives of those who do manage it easier. 
