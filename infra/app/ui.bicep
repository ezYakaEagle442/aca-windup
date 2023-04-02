// https://issues.redhat.com/browse/WINDUP-3774
// https://github.com/windup/windup-openshift/blob/master/templates/src/main/resources/web-template-empty-dir-executor.json#L309
// https://access.redhat.com/documentation/en-us/migration_toolkit_for_applications/5.0/html/web_console_guide/installing_the_web_console

param name string
param location string = resourceGroup().location
param tags object = {}

param applicationInsightsName string
param containerAppsEnvironmentName string
param containerRegistryName string
param imageName string = 'quay.io/windupeng/windup-web-openshift:latest'
param serviceName string = 'ui'

@allowed([
  8042
  8080
])
param appPort int = 8080

module ui '../core/host/container-app-ui.bicep' = {
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
    targetPort: appPort
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

output UI_IDENTITY_PRINCIPAL_ID string = ui.outputs.identityPrincipalId
output UI_NAME string = ui.outputs.name
output UI_URI string = ui.outputs.uri
output UI_IMAGE_NAME string = ui.outputs.imageName
