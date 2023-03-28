param containerRegistryName string
param principalId string

var acrPullRole = subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')

resource acaAcrPull 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry // Use when specifying a scope that is different than the deployment scope
  name: guid(principalId, 'Acr', acrPullRole)
  properties: {
    roleDefinitionId: acrPullRole
    principalType: 'ServicePrincipal'
    principalId: principalId
  }
}

output acaAcrPullRoleAssignmentId string = acaAcrPull.id
output acaAcrPullRoleAssignmentName string = acaAcrPull.name
output acaAcrPullRoleAssignmentCreatedOn string = acaAcrPull.properties.createdOn
output acaAcrPullRoleAssignmentCpdatedOn string = acaAcrPull.properties.updatedOn

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}
