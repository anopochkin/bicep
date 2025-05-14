@description('Globally unique name for the Storage Account. Defaults to a name with a unique string.')
param storageAccountName string = 'stlifecycle${uniqueString(resourceGroup().id)}'

@description('Location for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Name for the Blob Container.')
param containerName string = 'lifecycle-data-container'

@description('Number of days after modification to move blobs to Cool tier.')
@minValue(1)
param daysToCool int = 1

@description('Number of days after modification to move blobs to Archive tier.')
@minValue(1)
param daysToArchive int = 2

@description('Number of days after modification to delete blobs.')
@minValue(1)
param daysToDelete int = 3

@description('Azure Storage Account that will host the blob container and lifecycle policy.')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }

  @description('Default Azure Blob Service for the Storage Account.')
  resource blobService 'blobServices@2023-01-01' = {
    name: 'default'

    @description('Blob container for storing lifecycle-managed data.')
    resource blobContainer 'containers@2023-01-01' = {
      name: containerName
      properties: {
        publicAccess: 'None'
      }
    }
  }

  @description('Lifecycle management policy to move blobs to cool, archive, and then delete.')
  resource lifecycleManagementPolicy 'managementPolicies@2023-01-01' = {
    name: 'default'
    properties: {
      policy: {
        rules: [
          {
            enabled: true
            name: 'MoveToCoolArchiveDeleteRule'
            type: 'Lifecycle'
            definition: {
              actions: {
                baseBlob: {
                  tierToCool: {
                    daysAfterModificationGreaterThan: daysToCool
                  }
                  tierToArchive: {
                    daysAfterModificationGreaterThan: daysToArchive
                  }
                  delete: {
                    daysAfterModificationGreaterThan: daysToDelete
                  }
                }
              }
              filters: {
                blobTypes: [
                  'blockBlob'
                ]
                // Optional: To apply the policy only to a specific container
                // prefixMatch: [
                //  containerName
                // ]
              }
            }
          }
        ]
      }
    }
  }
}

