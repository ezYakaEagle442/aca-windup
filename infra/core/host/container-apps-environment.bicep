param name string
param location string = resourceGroup().location
param tags object = {}

param logAnalyticsWorkspaceName string

@description('The Storage Account name')
param azureStorageName string

@description('The Azure Files Share service service name')
param azureFileShareServiceName string = 'winupshare' 

@allowed([
  'log-analytics'
  'azure-monitor'
])
@description('Cluster configuration which enables the log daemon to export app logs to a destination. Currently only "log-analytics" is supported https://learn.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments?pivots=deployment-language-bicep#managedenvironmentproperties')
param logDestination string = 'log-analytics'

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

// https://learn.microsoft.com/en-us/azure/container-apps/storage-mounts?pivots=azure-resource-manager#azure-files
resource acastorage 'Microsoft.App/managedEnvironments/storages@2022-10-01' = {
  name: azureFileShareServiceName
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


resource appInsightsDiagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (logDestination=='azure-monitor') {
  name: 'dgs-windup-send-logs-and-metrics-to-log-analytics'
  scope: containerAppsEnvironment
  properties: {
    logAnalyticsDestinationType: 'AzureDiagnostics'
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        category: 'ContainerAppConsoleLogs'
        enabled: true
      }
      {
        category: 'ContainerAppSystemLogs'
        enabled: true
      }      
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}

/*
output appInsightsDiagnosticSettingsId string = appInsightsDiagnosticSettings.id
output appInsightsDiagnosticSettingsName string = appInsightsDiagnosticSettings.name
output appInsightsDiagnosticSettingsWorkspaceId string = appInsightsDiagnosticSettings.properties.workspaceId
output appInsightsDiagnosticSettingslogAnalyticsDestinationType string = appInsightsDiagnosticSettings.properties.logAnalyticsDestinationType
*/
