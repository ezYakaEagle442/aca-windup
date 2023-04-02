param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
// https://quay.io/repository/windupeng/windup-web-openshift-messaging-executor?tab=tags&tag=latest
param imageName string = 'quay.io/windupeng/windup-web-openshift-messaging-executor:latest'
param serviceName string = 'messaging-executor'

module messagingexecutor '../core/host/container-app-messaging-executor.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    name: name
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: [
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: applicationInsights.properties.ConnectionString
      }
    ]
    imageName: !empty(imageName) ? imageName : 'nginx:latest'
    targetPort: 80
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

output UI_IDENTITY_PRINCIPAL_ID string = ui.outputs.identityPrincipalId
output UI_NAME string = ui.outputs.name
output UI_URI string = ui.outputs.uri
output UI_IMAGE_NAME string = ui.outputs.imageName
