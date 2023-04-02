param name string
param location string = resourceGroup().location
param tags object = {}

param sku object
param storage object

@description('Azure Container Apps Outbound Public IP as an Array')
param azureContainerAppsOutboundPubIP array

@description('The PostgreSQL DB Admin Login. IMPORTANT: username can not start with prefix "pg_" which is reserved, ex: pg_adm would fails in Bicep. Admin login name cannot be azure_superuser, azuresu, azure_pg_admin, sa, admin, administrator, root, guest, dbmanager, loginmanager, dbo, information_schema, sys, db_accessadmin, db_backupoperator, db_datareader, db_datawriter, db_ddladmin, db_denydatareader, db_denydatawriter, db_owner, db_securityadmin, public')
param administratorLogin string = 'pgs_adm'

@secure()
param administratorLoginPassword string

@description('The PostgreSQL DB name.')
param dbName string = 'windup'

param allowAzureIPsFirewall bool = false
param allowAllIPsFirewall bool = false
param allowedSingleIPs array = []

param charset string = 'utf8'
param collation string = 'fr_FR.utf8' // select * from pg_collation ;

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

// Latest official version 2022-12-01 does not have Bicep types available
resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  location: location
  tags: tags
  name: name
  sku: sku
  properties: {
    version: version
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    storage: storage
    highAvailability: {
      mode: 'Disabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    replicationRole: 'None'    
  }
}
output POSTGRES_DOMAIN_NAME string = postgresServer.properties.fullyQualifiedDomainName
output POSTGRES_ID string = postgresServer.id
output POSTGRES_SERVER_NAME string = postgresServer.name

resource PostgreSQLDB 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' =  {
  name: dbName
  parent: postgresServer
  properties: {
    charset: charset
    collation: collation
  }
}

output PostgreSQLDBResourceID string = PostgreSQLDB.id
output PostgreSQLDBName string = PostgreSQLDB.name
  
 resource fwRuleAllowACA 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2022-12-01' = {
  name: 'Allow-ACA-OutboundPubIP'
  parent: postgresServer
  properties: {
    startIpAddress: azureContainerAppsOutboundPubIP[0]
    endIpAddress: azureContainerAppsOutboundPubIP[0]
  }
}
