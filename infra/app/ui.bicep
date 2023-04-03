/*
 https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
az deployment group create --name test-ui-module -f ./infra/app/ui.bicep -g rg-aca-windup \
-p containerAppsEnvironmentName=xxx \
-p applicationInsightsName=xxx \
-p location=westeurope \
-p containerRegistryName=XXX \
-p DB_PASSWORD=XXX \
-p GITHUB_WEBHOOK_SECRET=XXX \
-p GENERIC_WEBHOOK_SECRET=XXX \
-p JGROUPS_CLUSTER_PASSWORD=XXX \
-p SSO_SECRET=XXX \
-p MQ_CLUSTER_PASSWORD=XXX \
-p MQ_CLUSTER_PASSWORD=XXX \
-p JGROUPS_ENCRYPT_PASSWORD=XXX \
-p SSO_SAML_KEYSTORE_PASSWORD=XXX \
-p SSO_TRUSTSTORE_PASSWORD=XXX
*/


// https://issues.redhat.com/browse/WINDUP-3774
// https://github.com/windup/windup-openshift/blob/master/templates/src/main/resources/web-template-empty-dir-executor.json#L309
// https://access.redhat.com/documentation/en-us/migration_toolkit_for_applications/5.0/html/web_console_guide/installing_the_web_console

param location string = resourceGroup().location
param tags object = {}
param pgServerName string

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

@description('The applicationinsights-agent-3.x.x.jar file is downloaded in each Dockerfile. See https://learn.microsoft.com/en-us/azure/azure-monitor/app/java-in-process-agent')
param applicationInsightsAgentJarFilePath string = 'applicationinsights-agent-3.4.10.jar'

@description('The applicationinsights config file location')
param applicationInsightsConfigFile string = 'applicationinsights.json'

// Windup params: https://github.com/windup/windup-openshift/blob/master/templates/src/main/resources/web-template-empty-dir-executor.json#L734

@description('The name of the application.')
param APPLICATION_NAME string = 'windup-web-console'

@description('The value determines the approach used for transferring data between the UI components and the analysis engine.')
param MESSAGING_SERIALIZER string = 'http.post.serializer'

@description('Size of persistent storage for WINDUP volume.')
param WINDUP_VOLUME_CAPACITY string = '512G'

@description('Database name')
param DB_DATABASE string = 'windup'

param WINDUP_WEB_CONSOLE_POSTGRESQL_SERVICE_PORT int= 5432

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

@description('Queue names')
param MQ_QUEUES string = ''

@description('Topic names')
param MQ_TOPICS string = ''

// ###################################################


// 2022-02-01-preview needed for anonymousPullEnabled
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: containerRegistryName
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' existing = {
    name: pgServerName
}

resource postgreSQLDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' existing =  {
    name: DB_DATABASE
    parent: postgresServer
}

var secrets = [
  {
    name: 'registrypassword'
    value: containerRegistry.listCredentials().passwords[0].value
  }  
  {
    name: 'applicationinsightsconnectionstring'
    value: applicationInsights.properties.ConnectionString
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
    secretRef: 'applicationinsightsconnectionstring'
  }
  {
    name: 'IS_MASTER'
    value: 'true'
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
    name: 'WINDUP_WEB_CONSOLE_POSTGRESQL_SERVICE_HOST'
    value: postgresServer.properties.fullyQualifiedDomainName
  }
  {
    name: 'WINDUP_WEB_CONSOLE_POSTGRESQL_SERVICE_PORT'
    value: WINDUP_WEB_CONSOLE_POSTGRESQL_SERVICE_PORT
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
      value: string(AUTO_DEPLOY_EXPLODED)
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
      value: string(SSO_ENABLE_CORS)
  }
  {
      name: 'SSO_SAML_LOGOUT_PAGE'
      value: SSO_SAML_LOGOUT_PAGE
  }
  {
      name: 'SSO_DISABLE_SSL_CERTIFICATE_VALIDATION'
      value: string(SSO_DISABLE_SSL_CERTIFICATE_VALIDATION)
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
      value: 'MAX_POST_SIZE'
  }
  {
      name: 'SSO_FORCE_LEGACY_SECURITY'
      value: 'false'
  }

]  

module ui '../core/host/container-app-ui.bicep' = {
  name: '${serviceName}-container-app-module'
  params: {
    location: location
    tags: union(tags, { 'azd-service-name': serviceName })
    containerAppsEnvironmentName: containerAppsEnvironmentName
    containerRegistryName: containerRegistryName
    env: env
    secrets: secrets
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
