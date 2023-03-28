param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = 'quay.io/windupeng/windup-cli-openshift:latest'
param serviceName string = 'cli'

@description('The Storage Account name')
param azureStorageName string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

module cli '../core/host/container-app-cli.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    azureStorageName: azureStorageName
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
    ]
    imageName: imageName
    targetPort: 80
  }
}

output CLI_IDENTITY_PRINCIPAL_ID string = cli.outputs.identityPrincipalId
output CLI_NAME string = cli.outputs.name
output CLI_URI string = cli.outputs.uri
output CLI_IMAGE_NAME string = cli.outputs.imageName
