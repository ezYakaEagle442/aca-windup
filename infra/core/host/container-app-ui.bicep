// https://issues.redhat.com/browse/WINDUP-3774
// https://github.com/windup/windup-openshift/blob/master/templates/src/main/resources/web-template-empty-dir-executor.json#L309
// https://access.redhat.com/documentation/en-us/migration_toolkit_for_applications/5.0/html/web_console_guide/installing_the_web_console

/*
 https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
vim arrayContent.json
[
  "42.42.42.42"
]

az deployment group create --name test-ui -f ./infra/core/host/container-app-ui.bicep -g rg-aca-windup \
-p name=cb4hbdqtz5qf6 \
-p containerAppsEnvironmentName=cae-cb4hbdqtz5qf6 \
-p containerRegistryName=crcb4hbdqtz5qf6 \
-p imageName=crcb4hbdqtz5qf6.azurecr.io/windup/windup:latest

-p dummyArray=@arrayContent.json \
            
*/

param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param containerRegistryName string = ''

param containerName string = 'windup-ui'
param external bool = true
param imageName string = 'quay.io/windupeng/windup-web-openshift:latest'
param managedIdentity bool = true
param targetPort int = 8080

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
param containerCpuCoreCount string = '2.0' // should be 4 minimum

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
param containerMemory string = '4.0Gi'

param env array = []
param secrets array = []


// 2022-02-01-preview needed for anonymousPullEnabled
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource app 'Microsoft.App/containerApps@2022-10-01' = {
  name: 'windup-ui'
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
      secrets: secrets
      registries: [
        {
          server: '${containerRegistryName}.azurecr.io'
          username:containerRegistryName
          passwordSecretRef: 'registrypassword'
        }
      ]
    }
    template: {
      containers: [
        {
          /*
          command: [
            'bash', 'run_windup.sh'
          ]*/
          image: imageName
          name: containerName
          env: env
          /*
          https://learn.microsoft.com/en-us/azure/container-apps/health-probes?tabs=arm-template#restrictions
          exec probes aren't supported.: https://github.com/microsoft/azure-container-apps/issues/461

          probes: [
            {
              failureThreshold: 5
              exec: {
                command: [
                    /bin/bash
                    -c,
                    ${JBOSS_HOME}/bin/jboss-cli.sh --connect --commands='/core-service=management:read-boot-errors()' | grep '\"result\" => \\[]' && ${JBOSS_HOME}/bin/jboss-cli.sh --connect --commands=ls | grep 'server-state=running'"
                ]
            }
              initialDelaySeconds: 5
              periodSeconds: 10
              successThreshold: 1 
              timeoutSeconds: 2
              type: 'Liveness'
            }
            {
              failureThreshold: 5
              httpGet: {
                path: '???'
                port: targetPort
                scheme: 'HTTP'
              }
              initialDelaySeconds: 5
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 2
              type: 'Readiness'
            }
            
            {
              failureThreshold: 5
              httpGet: {
                path: '???'
                port: targetPort
                scheme: 'HTTP'
              }
              initialDelaySeconds: 5
              periodSeconds: 10
              successThreshold: 1
              timeoutSeconds: 3
              type: 'Startup'              
            }         
          ]
          */
        
          resources: {
            cpu: any(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      } 
    }
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-10-01' existing = {
  name: containerAppsEnvironmentName
}

output identityPrincipalId string = managedIdentity ? app.identity.principalId : ''
output imageName string = imageName
output name string = app.name
output uri string = 'https://${app.properties.configuration.ingress.fqdn}'
output latestRevisionName string = app.properties.latestRevisionName
