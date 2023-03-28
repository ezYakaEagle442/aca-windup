/*
 https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
vim arrayContent.json
[
  "42.42.42.42"
]

az deployment group create --name test-storage -f ./infra/core/storage/storage.bicep -g rg-aca-windup -p azureFileShareServiceName=winupshare


-p dummyArray=@arrayContent.json \
            
*/

@description('The Storage Account name')
param azureStorageName string

@description('The location of the Azure resources.')
param location string = resourceGroup().location

@description('The Azure Files service service name')
param azureFileServiceName string = 'default' 

@description('The Azure Files Share service service name')
param azureFileShareServiceName string

@description('The VNet rules to whitelist for the Strorage Account')
param  vNetRules array = []

@description('The IP rules to whitelist for the Strorage Account')
param  ipRules array = []

@description('The Identity Tags. See https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources?tabs=bicep#apply-an-object')
param tags object = {
  Environment: 'Dev'
  Dept: 'IT'
  Scope: 'EU'
  CostCenter: '442'
  Owner: 'Windup'
}

// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep
resource azurestorage 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: azureStorageName
  location: location
  tags: tags
  sku: {
    name: 'Premium_ZRS'
  }
  kind: 'FileStorage'
  identity: {
    type: 'SystemAssigned' 
  }
  properties: {
    //accessTier: 'Hot'
    //allowBlobPublicAccess: false
    allowCrossTenantReplication: false
    allowedCopyScope: 'AAD'
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    // https://learn.microsoft.com/en-us/azure/storage/blobs/storage-feature-support-in-storage-accounts
    dnsEndpointType: 'Standard' // AzureDnsZone in Preview  https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/storage/common/storage-account-overview.md#azure-dns-zone-endpoints-preview

    //isNfsV3Enabled: true
    keyPolicy: {
      keyExpirationPeriodInDays: 180
    }
    //largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules:  [for ipRule in ipRules: {
        action: 'Allow'
        value: ipRule
      }]
      virtualNetworkRules:  [for vNetId in vNetRules: {
        action: 'Allow'
        id: vNetId
      }]
    }
    publicNetworkAccess: 'Enabled'
    sasPolicy: {
      expirationAction: 'Log'
      sasExpirationPeriod: '30.23:59:00'
    }
    supportsHttpsTrafficOnly: true
  }
}

output azurestorageId string = azurestorage.id
output azurestorageName string = azurestorage.name
output azurestorageFileEndpoint string = azurestorage.properties.primaryEndpoints.file
// output azurestorageHttpEndpoint string = azurestorage.properties.primaryEndpoints.blob

// outputs-should-not-contain-secrets
// output azurestorageSasToken string = azurestorage.listAccountSas().accountSasToken
// output azurestorageKey0 string = azurestorage.listKeys().keys[0].value
// output azurestorageKey1 string = azurestorage.listKeys().keys[1].value



// https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/fileservices?pivots=deployment-language-bicep
resource azurefileservice 'Microsoft.Storage/storageAccounts/fileServices@2022-09-01' = {
  name: azureFileServiceName
  parent: azurestorage
}

resource azurefileshareservice 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: azureFileShareServiceName
  parent: azurefileservice
  properties: {
    enabledProtocols: 'NFS'
    metadata: {}
    rootSquash: 'NoRootSquash'
    shareQuota: 1024
  }  
}


/*
resource azureblobservice 'Microsoft.Storage/storageAccounts/blobServices@2022-09-01' = {
  name: azureBlobServiceName
  parent: azurestorage
  properties: {
    containerDeleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 1
      enabled: true
    }
    // defaultServiceVersion: ''
    deleteRetentionPolicy: {
      allowPermanentDelete: true
      days: 1
      enabled: true
    }
    isVersioningEnabled: false
    lastAccessTimeTrackingPolicy: {
      blobType: [
        'blockBlob'
      ]
      enable: false
      name: 'AccessTimeTracking'
      trackingGranularityInDays: 1
    }
    restorePolicy: {
      days: 2
      enabled: false
    }
  }
}
output azureblobserviceId string = azureblobservice.id
output azureblobserviceName string = azureblobservice.name

resource blobcontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2022-09-01' = {
  name: blobContainerName
  parent: azureblobservice
  properties: {
    enableNfsV3AllSquash: false
    enableNfsV3RootSquash: false

    publicAccess: 'Container'
  }
}
output blobcontainerId string = blobcontainer.id
output blobcontainerName string = blobcontainer.name
*/
