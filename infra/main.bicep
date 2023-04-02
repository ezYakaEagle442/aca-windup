/*
 https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
az deployment group create --name test-main-cli -f ./infra/main.bicep -g rg-aca-windup \
-p resourceGroupName=rg-aca-windup \
-p azureFileShareServiceName=winupshare \
-p location=westeurope            
*/

targetScope = 'subscription'

@minLength(1)
@maxLength(21)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('The Storage Account name')
param azureStorageName string = ''

@description('The Azure Files Share service service name')
param azureFileShareServiceName string = ''

// Optional parameters to override the default azd resource naming conventions. Update the main.parameters.json file to provide values. e.g.,:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param applicationInsightsDashboardName string = ''
param applicationInsightsName string = ''
param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''

var abbrs = loadJsonContent('./abbreviations.json')
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))
var tags = { 'azd-env-name': environmentName }

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Container apps host (including container registry)
module containerApps './core/host/container-apps.bicep' = {
  name: 'container-apps'
  scope: rg
  params: {
    name: 'app'
    containerAppsEnvironmentName: !empty(containerAppsEnvironmentName) ? containerAppsEnvironmentName : '${abbrs.appManagedEnvironments}${resourceToken}'
    containerRegistryName: !empty(containerRegistryName) ? containerRegistryName : '${abbrs.containerRegistryRegistries}${resourceToken}'
    location: location
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    azureStorageName: storage.outputs.azurestorageName
    azureFileShareServiceName: azureFileShareServiceName
  }
  dependsOn: [
    storage
  ]  
}

output AZURE_CONTAINER_ENVIRONMENT_NAME string = containerApps.outputs.containerAppsEnvironmentName
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerApps.outputs.registryLoginServer
output AZURE_CONTAINER_REGISTRY_NAME string = containerApps.outputs.registryName

// Monitor application with Azure Monitor
module storage './core/storage/storage.bicep' = {
  name: 'storage'
  scope: rg
  params: {
    location: location
    tags: tags
    azureStorageName: !empty(azureStorageName) ? azureStorageName : '${abbrs.storageStorageAccounts}${resourceToken}'
    azureFileShareServiceName: !empty(azureFileShareServiceName) ? azureFileShareServiceName : '${resourceToken}'
  }
}

output azurestorageId string = storage.outputs.azurestorageId
output azurestorageName string = storage.outputs.azurestorageName
output azurestorageFileEndpoint string = storage.outputs.azurestorageFileEndpoint
output azureFileServiceId string = storage.outputs.azureFileServiceId
output azureFileServiceName string = storage.outputs.azureFileServiceName
output azureFileShareServiceId string = storage.outputs.azureFileShareServiceId
output azureFileShareServiceName string = storage.outputs.azureFileShareServiceName


// Monitor application with Azure Monitor
module monitoring './core/monitor/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
    logAnalyticsName: !empty(logAnalyticsName) ? logAnalyticsName : '${abbrs.operationalInsightsWorkspaces}${resourceToken}'
    applicationInsightsName: !empty(applicationInsightsName) ? applicationInsightsName : '${abbrs.insightsComponents}${resourceToken}'
    applicationInsightsDashboardName: !empty(applicationInsightsDashboardName) ? applicationInsightsDashboardName : '${abbrs.portalDashboards}${resourceToken}'
  }
}

// App outputs
output APPLICATIONINSIGHTS_CONNECTION_STRING string = monitoring.outputs.applicationInsightsConnectionString
output APPLICATIONINSIGHTS_NAME string = monitoring.outputs.applicationInsightsName

output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
