param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''
param logAnalyticsWorkspaceName string = ''

module containerAppsEnvironment 'container-apps-environment.bicep' = {
  name: '${name}-container-apps-environment'
  params: {
    name: containerAppsEnvironmentName
    location: location
    tags: tags
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
  }
}

output containerAppsEnvironmentName string = containerAppsEnvironment.outputs.containerAppsEnvironmentName
output containerAppsEnvironmentId string = containerAppsEnvironment.outputs.containerAppsEnvironmentId
output containerAppsEnvironmentDefaultDomain string = containerAppsEnvironment.outputs.containerAppsEnvironmentDefaultDomain
output containerAppsEnvironmentStaticIp string = containerAppsEnvironment.outputs.containerAppsEnvironmentStaticIp


module containerRegistry 'container-registry.bicep' = {
  name: '${name}-container-registry'
  params: {
    name: containerRegistryName
    location: location
    tags: tags
  }
}
output registryLoginServer string = containerRegistry.outputs.loginServer
output registryName string = containerRegistry.outputs.name
