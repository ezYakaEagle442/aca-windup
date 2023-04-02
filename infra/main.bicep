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
param pgServerName string = ''
param containerRegistryName string = ''
param logAnalyticsName string = ''
param resourceGroupName string = ''

@description('The PostgreSQL DB Admin Login. IMPORTANT: username can not start with prefix "pg_" which is reserved, ex: pg_adm would fails in Bicep. Admin login name cannot be azure_superuser, azuresu, azure_pg_admin, sa, admin, administrator, root, guest, dbmanager, loginmanager, dbo, information_schema, sys, db_accessadmin, db_backupoperator, db_datareader, db_datawriter, db_ddladmin, db_denydatareader, db_denydatawriter, db_owner, db_securityadmin, public')
param administratorLogin string = 'pgs_adm'

@secure()
param administratorLoginPassword string

@description('The PostgreSQL DB name.')
param dbName string = 'windup'

// https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/how-to-deploy-on-azure-free-account
@description('Azure database for PostgreSQL SKU')
@allowed([
  'Standard_D4s_v3'
  'Standard_D2s_v3'
  'Standard_B1ms'
])
param databaseSkuName string = 'Standard_B1ms'

@description('Azure database for PostgreSQL pricing tier')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param databaseSkuTier string = 'Burstable'

@description('PostgreSQL version. See https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions')
@allowed([
  '14'
  '13'
  '12'
  '11'
])
param version string = '14' // https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-supported-versions

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


module hello './core/host/aca-hello.bicep' = {
  name: 'hello-app'
  scope: rg
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': 'hello' })
    containerAppsEnvironmentName: containerAppsEnvironmentName
  }
  dependsOn: [
    containerApps
  ]
}

module db './core/database/postgresql/flexibleserver.bicep' = {
  name: 'postgresql'
  scope: rg
  params: {
    location: location
    tags: tags
    azureContainerAppsOutboundPubIP: hello.outputs.helloContainerAppoutboundIpAddresses
    allowedSingleIPs: hello.outputs.helloContainerAppoutboundIpAddresses
    version: version
    databaseSkuName: databaseSkuName
    databaseSkuTier: databaseSkuTier
    dbName: dbName
    name: !empty(pgServerName) ? pgServerName : '${abbrs.dBforPostgreSQLServers}${resourceToken}'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
  }
  dependsOn: [
    hello
  ]
}

output postgresqlId string = db.outputs.POSTGRES_ID
output postgresqlServerName string = db.outputs.POSTGRES_SERVER_NAME
output postgresqlDomainName string = db.outputs.POSTGRES_DOMAIN_NAME


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
