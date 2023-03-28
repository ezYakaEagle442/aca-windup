/*
 https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
vim arrayContent.json
[
  "42.42.42.42"
]

az deployment group create --name test-cli -f ./infra/core/host/container-app-cli.bicep -g rg-aca-windup \
-p name=cb4hbdqtz5qf6 \
-p containerAppsEnvironmentName=cae-cb4hbdqtz5qf6 \
-p containerRegistryName=crcb4hbdqtz5qf6

-p dummyArray=@arrayContent.json \
            
*/

param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param windupInput string = 'spring-petclinic-3.0.0-SNAPSHOT.jar'
param windupTarget string = 'azure-appservice'

param containerName string = 'windup-cli'
param containerRegistryName string = ''
param env array = []
param external bool = true
param imageName string = 'quay.io/windupeng/windup-cli-openshift:latest'
param windupBinaryPath string = '/opt/migrationtoolkit/bin/windup-cli'
param packages string = 'org.springframework.samples.petclinic'
param managedIdentity bool = true
param targetPort int = 8080

@description('The Storage Account name')
param azureStorageName string

@allowed([
  '0.25'
  '0.5'
  '0.75'
  '1.0' 
  '1.25'
  '1.5'
  '1.75'
  '2.0'    
])
@description('CPU cores allocated to a single container instance, e.g. 0.5. The total CPU and memory allocations requested for all the containers in a container app must add up to one of the following combinations. See https://learn.microsoft.com/en-us/azure/container-apps/containers#configuration')
param containerCpuCoreCount string = '1.0'

@allowed([
  '0.5Gi'
  '1.0Gi'  
  '1.5Gi'
  '2.0Gi'    
  '2.5Gi'
  '3.0Gi'  
  '3.5Gi'
  '4.0Gi'    
])
@description('Memory allocated to a single container instance, e.g. 1Gi. The total CPU and memory allocations requested for all the containers in a container app must add up to one of the following combinations. See https://learn.microsoft.com/en-us/azure/container-apps/containers#configuration')
param containerMemory string = '2.0Gi'

resource app 'Microsoft.App/containerApps@2022-10-01' = {
  name: 'windup-cli'
  location: location
  tags: tags
  identity: { type: managedIdentity ? 'SystemAssigned' : 'None' }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: external
        targetPort: targetPort
        transport: 'auto'
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          command: [
            '${windupBinaryPath}', '--input /winshare/input/${windupInput}', '--target ${windupTarget}', '--output /winshare/output/', '--packages ${packages}',  '--overwrite', '-b'            
          ]          
          image: imageName
          name: containerName

          volumeMounts: [
            {
              mountPath: '/winshare'
              volumeName: 'azurefiles'
            }
          ]          
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      volumes: [
        {
          name: 'azurefiles'
          storageType: 'AzureFile'
          storageName: azureStorageName

        }
      ]

    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvironmentName
}

// 2022-02-01-preview needed for anonymousPullEnabled
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

output identityPrincipalId string = managedIdentity ? app.identity.principalId : ''
output imageName string = imageName
output name string = app.name
output uri string = 'https://${app.properties.configuration.ingress.fqdn}'
output latestRevisionName string = app.properties.latestRevisionName
