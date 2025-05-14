# Azure Blob Storage Lifecycle Management with Bicep 

This project demonstrates how to deploy an Azure Storage Account with a configured lifecycle management policy using Bicep. The lifecycle policy automatically transitions blobs through different access tiers (Hot, Cool, Archive) and eventually deletes them to optimize storage costs.

## Project Overview

The goal of this project is to automate the setup of an Azure Storage Account with a lifecycle management policy. This includes:
- Creation of a Storage Account (StorageV2, Standard_LRS).
- Creation of a default blob container.
- Configuration of a lifecycle policy that:
    - Moves blobs to the Cool tier after a specified number of days.
    - Moves blobs to the Archive tier after a further specified number of days.
    - Deletes blobs after a final specified number of days.

## Features

- **Infrastructure as Code (IaC):** Uses Bicep for declarative resource deployment.
- **Automated Lifecycle Management:** Optimizes storage costs by moving less frequently accessed data to cheaper tiers and deleting old data.
- **Parameterization:** The Bicep template is parameterized for flexibility in naming, location, and lifecycle timings.
- **Secure by Default:** Configures the storage account to disallow public blob access and enforce HTTPS.

## Architecture

The Bicep template deploys the following Azure resources:
1.  **Azure Resource Group** (created manually before deployment).
2.  **Azure Storage Account** (`Microsoft.Storage/storageAccounts`):
    -   SKU: Standard_LRS
    -   Kind: StorageV2
3.  **Azure Blob Service** (`Microsoft.Storage/storageAccounts/blobServices`):
    -   Default service.
4.  **Azure Blob Container** (`Microsoft.Storage/storageAccounts/blobServices/containers`):
    -   Named as per `containerName` parameter.
    -   Public Access: None.
5.  **Azure Management Policy** (`Microsoft.Storage/storageAccounts/managementPolicies`):
    -   Contains rules for tiering (Cool, Archive) and deletion based on `daysToCool`, `daysToArchive`, and `daysToDelete` parameters.

## Prerequisites

- Azure CLI installed and configured.
- An active Azure Subscription.
- Bicep CLI (usually comes with Azure CLI or can be installed separately).
- Git (optional, for cloning).

## Deployment Steps

### 1. Clone the Repository (Optional)
If you have this project on GitHub, clone it:
```
git clone https://github.com/anopochkin/bicep.git
cd bicep 
```

### 2. Login to Azure and Create a Resource Group
Authenticate with Azure CLI (ensure Azure CLI is installed and in your PATH). The commands below are for PowerShell.
```
az login
```

```
$ResourceGroupName = "rg-blob-lifecycle-project"  # You can choose a different name
$Location = "eastus"  # Choose an Azure region that suits you

az group create --name "$ResourceGroupName" --location "$Location"
```

### 3. Deploy the Bicep Template
Deploy the main.bicep file to the created resource group:
```
az deployment group create `
  --resource-group "$ResourceGroupName" `
  --template-file "./main.bicep" 

```

## Upload Test Files and Monitor Blob Tiers

After deployment, you will need to upload test files to the created container and then monitor their lifecycle.
**Note:** You might need the `Storage Blob Data Contributor` role on the deployed Storage Account to upload blobs using `--auth-mode login`.

The commands below are for PowerShell.

```powershell
# Ensure $ResourceGroupName is set to the name of the resource group used in "Deployment Steps"
# For example: $ResourceGroupName = "rg-blob-lifecycle-project"

# 1. Get the deployed Storage Account name:
$DeployedStorageAccountName = (az storage account list --resource-group "$ResourceGroupName" --query "[0].name" -o tsv)
Write-Host "Using Storage Account: $DeployedStorageAccountName"

# 2. Set the container name (default from Bicep):
$DeployedContainerName = "lifecycle-data-container"

# 3. Create and upload test files (example):
New-Item -ItemType File -Name "testfile1.txt" -Force | Out-Null
New-Item -ItemType File -Name "photo_archive.zip" -Force | Out-Null

az storage blob upload --account-name "$DeployedStorageAccountName" --container-name "$DeployedContainerName" --name "testfile1.txt" --file "testfile1.txt" --auth-mode login
az storage blob upload --account-name "$DeployedStorageAccountName" --container-name "$DeployedContainerName" --name "photo_archive.zip" --file "photo_archive.zip" --auth-mode login
Write-Host "Test files uploaded."

# 4. Example command to check blob tier (for testfile1.txt):
Write-Host "--- Checking tier for testfile1.txt ---"
Get-Date
az storage blob show `
  --account-name "$DeployedStorageAccountName" `
  --container-name "$DeployedContainerName" `
  --name "testfile1.txt" `
  --auth-mode login `
  --query "{Name:name, Tier:properties.blobTier, LastModified:properties.lastModified}"

# Repeat the above command for other files or at different time intervals for your tests.


*   **Test 1 : Initially: Hot**
    *   See details and result: : ![Test 1 Result](hot.png)
        
*   **Test 2 : After daysToCool (default 1 day): Cool**
    *   See details and result: : ![Test 2 Result](cool.png)

*   **Test 3 : After daysToArchive (default 2 days): Archive**
    *   See details and result: : ![Test 3 Result](archive.png)

*   **Test 4 : After daysToDelete (default 3 days): Blobs should be deleted.**
    *   See details and result: : ![Test 4 Result](deleted.png)

## Cleanup
To remove all resources created by this project, delete the resource group:
```
az group delete --name "$RESOURCE_GROUP_NAME" --yes --no-wait
```
