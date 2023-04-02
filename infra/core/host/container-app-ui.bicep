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

param name string
param location string = resourceGroup().location
param tags object = {}

param containerAppsEnvironmentName string = ''
param containerName string = 'windup-ui'
param containerRegistryName string = ''
param external bool = true
param imageName string
param managedIdentity bool = true
param targetPort int = 8080

@description('The applicationinsights-agent-3.x.x.jar file is downloaded in each Dockerfile. See https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-in-process-agent')
param applicationInsightsAgentJarFilePath string = 'applicationinsights-agent-3.4.10.jar'

@description('The applicationinsights config file location')
param applicationInsightsConfigFile string = 'applicationinsights.json'

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


// Windup params: https://github.com/windup/windup-openshift/blob/master/templates/src/main/resources/web-template-empty-dir-executor.json#L734

@description('The name of the application.')
param APPLICATION_NAME string = 'windup-web-console'

@description('The value determines the approach used for transferring data between the UI components and the analysis engine.')
param MESSAGING_SERIALIZER string = 'http.post.serializer'

@description('Size of persistent storage for WINDUP volume.')
param WINDUP_VOLUME_CAPACITY string = '512G'

@description('Database name')
param DB_DATABASE string = 'windup'

@description('Size of persistent storage for database volume.')
param VOLUME_CAPACITY string = '42G'

@description('Database user name')
param DB_USERNAME string = 'windup'

@secure()
@description('Database user password')
param DB_PASSWORD string

@secure()
@description('GitHub trigger secret')
param GITHUB_WEBHOOK_SECRET string

@secure()
@description('Generic build trigger secret')
param GENERIC_WEBHOOK_SECRET string

@secure()
@description('JGroups cluster password')
param JGROUPS_CLUSTER_PASSWORD string

@secure()
@description('The SSO Client Secret for Confidential Access')
param SSO_SECRET string

@description('The value of the user name for the images from Quay to be used')
param DOCKER_IMAGES_USER string = ''

@description('The value of the tag for the images from Quay to be used')
param DOCKER_IMAGES_TAG string = 'latest'

@description('The maximum value of the size the an HTTP post request')
param MAX_POST_SIZE int = 4294967296

// ################ below params are optional ########


@description('Custom hostname for http service route.  Leave blank for default hostname')
param HOSTNAME_HTTP string = ''

@description('Database JNDI name used by application to resolve the datasource, e.g. java:/jboss/datasources/postgresql')
param DB_JNDI string = 'java:jboss/datasources/WindupServicesDS'

@secure()
@description('A-MQ cluster admin password')
param MQ_CLUSTER_PASSWORD string

@description('Namespace in which the ImageStreams for Red Hat Middleware images are installed. These ImageStreams are normally installed in the openshift namespace. You should only need to modify this if you have installed the ImageStreams in a different namespace/project.')
param IMAGE_STREAM_NAMESPACE string = 'openshift'

@description('The name of the secret containing the keystore file')
param JGROUPS_ENCRYPT_SECRET string = 'wildfly-app-secret'

@description('The name of the keystore file within the secret')
param JGROUPS_ENCRYPT_KEYSTORE string = 'jgroups.jceks'

@description('The name associated with the server certificate')
param JGROUPS_ENCRYPT_NAME string = ''

@secure()
@description('The password for the keystore and certificate')
param JGROUPS_ENCRYPT_PASSWORD string

@description('Controls whether exploded deployment content should be automatically deployed')
param AUTO_DEPLOY_EXPLODED bool = false

@description('The URL for the SSO server (e.g. https://secure-sso-myproject.example.com/auth).  This is the URL through which the user will be redirected when a login or token is required by the application.')
param SSO_AUTH_SERVER_URL string = ''

@description('The SSO realm to which the application client(s) should be associated (e.g. demo).')
param SSO_REALM string = ''

@description('The SSO SSL Required behaviour. E.g. EXTERNAL, NONE, ALL')
param SSO_SSL_REQUIRED string = 'EXTERNAL'

@description('The SSO Client Id.')
param SSO_CLIENT_ID string = ''

@description('SSO Client Access Type')
param SSO_BEARER_ONLY string = ''

@description('The name of the secret containing the keystore file')
param SSO_SAML_KEYSTORE_SECRET string = 'wildfly-app-secret'

@description('The name of the keystore file within the secret')
param SSO_SAML_KEYSTORE string = 'keystore.jks'

@description('The name associated with the server certificate')
param SSO_SAML_CERTIFICATE_NAME string = 'jboss'

@secure()
@description('The password for the keystore and certificate')
param SSO_SAML_KEYSTORE_PASSWORD string

@description('Enable CORS for SSO applications')
param SSO_ENABLE_CORS bool = false

@description('SSO logout page for SAML applications')
param SSO_SAML_LOGOUT_PAGE string = '/'

@description('If true SSL communication between Wildfly and the SSO Server will be insecure (i.e. certificate validation is disabled with curl)')
param SSO_DISABLE_SSL_CERTIFICATE_VALIDATION bool = false

@description('The name of the truststore file within the secret (e.g. truststore.jks)')
param SSO_TRUSTSTORE string = 'truststore.jks'

@secure()
@description('The password for the truststore and certificate (e.g. mykeystorepass)')
param SSO_TRUSTSTORE_PASSWORD string

@description('The name of the secret containing the truststore file (e.g. truststore-secret). Used for volume secretName')
param SSO_TRUSTSTORE_SECRET string = 'wildfly-app-secret'

@description('Sets xa-pool/min-pool-size for the configured datasource.')
param DB_MIN_POOL_SIZE string = ''

@description('Sets xa-pool/max-pool-size for the configured datasource.')
param DB_MAX_POOL_SIZE string = ''

@description('Sets transaction-isolation for the configured datasource.')
param DB_TX_ISOLATION string = ''

@description('The maximum number of client connections allowed. This also sets the maximum number of prepared transactions.')
param POSTGRESQL_MAX_CONNECTIONS int = 200

@description('Configures how much memory is dedicated to PostgreSQL for caching data.')
param POSTGRESQL_SHARED_BUFFERS string = ''

@description('Queue names')
param MQ_QUEUES string = ''

@description('Topic names')
param MQ_TOPICS string = ''

// ###################################################


var secrets = [
  {
    name: 'registry-password'
    value: containerRegistry.listCredentials().passwords[0].value
  }  
  {
    name: 'application-insights-connectionstring'
    value: appInsights.properties.ConnectionString
  }
  {
    name: 'dbpassword'
    value: DB_PASSWORD
  }
  {
    name: 'githubwebhooksecret'
    value: GITHUB_WEBHOOK_SECRET
  }
  {
    name: 'genericwebhooksecret'
    value: GENERIC_WEBHOOK_SECRET
  }
  {
    name: 'jgroupsclusterpassword'
    value: JGROUPS_CLUSTER_PASSWORD
  }
  {
    name: 'ssosecret'
    value: SSO_SECRET
  }
  {
    name: 'mqclusterpassword'
    value: MQ_CLUSTER_PASSWORD
  }   
  {
    name: 'jgroupsencryptpassword'
    value: JGROUPS_ENCRYPT_PASSWORD
  }
  {
    name: 'ssosamlkeystorepassword'
    value: SSO_SAML_KEYSTORE_PASSWORD
  }   
  {
    name: 'ssotruststorepassword'
    value: SSO_TRUSTSTORE_PASSWORD
  }  
]

var env = [
  {
    // https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-config#configuration-file-path
    name: 'APPLICATIONINSIGHTS_CONFIGURATION_FILE'
    value: applicationInsightsConfigFile
  }                      
  {
    // https://docs.microsoft.com/en-us/azure/azure-monitor/app/java-in-process-agent#set-the-application-insights-connection-string
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    secretRef: 'application-insights-connectionstring'
  }                       
  {
    name: 'IS_MASTER'
    value: true
  }
  {
      name: 'MESSAGING_SERIALIZER'
      value: MESSAGING_SERIALIZER
  }
  {
      name: 'DB_SERVICE_PREFIX_MAPPING'
      value: '${APPLICATION_NAME}-postgresql=DB'
  }
  {
      name: 'DB_JNDI'
      value: DB_JNDI
  }
  {
      name: 'DB_USERNAME'
      value: DB_USERNAME
  }
  {
      name: 'DB_PASSWORD'
      secretRef: 'dbpassword'
  }
  {
      name: 'DB_DATABASE'
      value: DB_DATABASE
  }
  {
      name: 'TX_DATABASE_PREFIX_MAPPING'
      value: '${APPLICATION_NAME}-postgresql=DB'
  }
  {
      name: 'DB_MIN_POOL_SIZE'
      value: DB_MIN_POOL_SIZE
  }
  {
      name: 'DB_MAX_POOL_SIZE'
      value: DB_MAX_POOL_SIZE
  }
  {
      name: 'DB_TX_ISOLATION'
      value: DB_TX_ISOLATION
  }
  {
      name: 'OPENSHIFT_KUBE_PING_LABELS'
      value: 'application=${APPLICATION_NAME}'
  }
  {
      name: 'OPENSHIFT_KUBE_PING_NAMESPACE'
      value: ''
  }
  {
      name: 'HTTPS_KEYSTORE_DIR'
      value: '/etc/wildfly-secret-volume'
  }
  {
      name: 'MQ_CLUSTER_PASSWORD'
      secretRef: 'mqclusterpassword'
  }
  {
      name: 'MQ_QUEUES'
      value: MQ_QUEUES
  }
  {
      name: 'MQ_TOPICS'
      value: MQ_TOPICS
  }
  {
      name: 'JGROUPS_ENCRYPT_SECRET'
      secretRef: 'jgroupsencryptpassword'
  }
  {
      name: 'JGROUPS_ENCRYPT_KEYSTORE_DIR'
      value: '/etc/jgroups-encrypt-secret-volume'
  }
  {
      name: 'JGROUPS_ENCRYPT_KEYSTORE'
      value: JGROUPS_ENCRYPT_KEYSTORE
  }
  {
      name: 'JGROUPS_ENCRYPT_NAME'
      value: JGROUPS_ENCRYPT_NAME
  }
  {
      name: 'JGROUPS_ENCRYPT_PASSWORD'
      secretRef: 'jgroupsencryptpassword'
  }
  {
      name: 'JGROUPS_CLUSTER_PASSWORD'
      secretRef: 'jgroupsclusterpassword'
  }
  {
      name: 'AUTO_DEPLOY_EXPLODED'
      value: AUTO_DEPLOY_EXPLODED
  }
  {
      name: 'DEFAULT_JOB_REPOSITORY'
      value: '${APPLICATION_NAME}-postgresql'
  }
  {
      name: 'TIMER_SERVICE_DATA_STORE'
      value: '${APPLICATION_NAME}-postgresql'
  }
  {
      name: 'SSO_AUTH_SERVER_URL'
      value: SSO_AUTH_SERVER_URL
  }
  {
      name: 'SSO_REALM'
      value: SSO_REALM
  }
  {
      name: 'SSO_SSL_REQUIRED'
      value: SSO_SSL_REQUIRED
  }
  {
      name: 'SSO_CLIENT_ID'
      value: SSO_CLIENT_ID
  }
  {
      name: 'SSO_BEARER_ONLY'
      value: SSO_BEARER_ONLY
  }
  {
      name: 'SSO_SAML_KEYSTORE_SECRET'
      value: SSO_SAML_KEYSTORE_SECRET
  }
  {
      name: 'SSO_SAML_KEYSTORE'
      value: SSO_SAML_KEYSTORE
  }
  {
      name: 'SSO_SAML_KEYSTORE_DIR'
      value: '/etc/sso-saml-secret-volume'
  }
  {
      name: 'SSO_SAML_CERTIFICATE_NAME'
      value: SSO_SAML_CERTIFICATE_NAME
  }
  {
      name: 'SSO_SAML_KEYSTORE_PASSWORD'
      secretRef: 'ssosamlkeystorepassword'
  }
  {
      name: 'SSO_SECRET'
      value: SSO_SECRET
  }
  {
      name: 'SSO_ENABLE_CORS'
      value: SSO_ENABLE_CORS
  }
  {
      name: 'SSO_SAML_LOGOUT_PAGE'
      value: SSO_SAML_LOGOUT_PAGE
  }
  {
      name: 'SSO_DISABLE_SSL_CERTIFICATE_VALIDATION'
      value: SSO_DISABLE_SSL_CERTIFICATE_VALIDATION
  }
  {
      name: 'SSO_TRUSTSTORE'
      value: SSO_TRUSTSTORE
  }
  {
      name: 'SSO_TRUSTSTORE_DIR'
      value: '/etc/sso-secret-volume'
  }
  {
      name: 'SSO_TRUSTSTORE_PASSWORD'
      secretRef: 'ssotruststorepassword'
  }
  {
      name: 'GC_MAX_METASPACE_SIZE'
      value: '512'
  }
  {
      name: 'MAX_POST_SIZE'
      value: MAX_POST_SIZE
  }
  {
      name: 'SSO_FORCE_LEGACY_SECURITY'
      value: 'false'
  }

]  

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
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          /*
          command: [
            './application' "-Dquarkus.http.host=0.0.0.0' 'java' '-javaagent:${applicationInsightsAgentJarFilePath}'
          ]*/
        
          image: imageName
          name: containerName
          env: env
          resources: {
            cpu: json(containerCpuCoreCount)
            memory: containerMemory
          }
        }
      ]      
    }

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
  scale: {
    minReplicas: 1
    maxReplicas: 10
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
