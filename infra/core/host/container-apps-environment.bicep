param name string
param location string = resourceGroup().location
param tags object = {}

param logAnalyticsWorkspaceName string

@description('A UNIQUE name')
@maxLength(21)
param appName string = 'windup${uniqueString(resourceGroup().id, subscription().id)}'

@description('The Storage Account name')
param azureStorageName string = 'sta${appName}'

@description('The Azure Files service service name')
param azureFileServiceName string = 'default' 

@description('The Azure Files Share service service name')
param azureFileShareServiceName string = 'winupshare' 

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

output containerAppsEnvironmentName string = containerAppsEnvironment.name
output containerAppsEnvironmentId string = containerAppsEnvironment.id
output containerAppsEnvironmentDefaultDomain string = containerAppsEnvironment.properties.defaultDomain
output containerAppsEnvironmentStaticIp string = containerAppsEnvironment.properties.staticIp


resource azurestorage 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: azureStorageName
}

resource acastorage 'Microsoft.App/managedEnvironments/storages@2022-10-01' = {
  name: 'string'
  parent: containerAppsEnvironment
  properties: {
    azureFile: {
      accessMode: 'ReadWrite'
      accountKey: azurestorage.listAccountSas().accountSasToken
      accountName: azureStorageName
      shareName: azureFileShareServiceName
    }
  }
  dependsOn: [
    azurestorage
  ]
}

output acaStorageId string = acastorage.id
output acaStorageName string = acastorage.name
