/* https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deploy-cli#inline-parameters 
vim arrayContent.json
[
  "42.42.42.42"
]

az deployment group create --name test-LA -f ./infra/core/monitor/loganalytics.bicep -g rg-aca-windup -p name=law-test -p laSKU=Free

-p dummyArray=@arrayContent.json \

az monitor log-analytics workspace create -n $analytics_workspace_name --location $location -g $rg_name --verbose

*/


param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'CapacityReservation'
  'LACluster'
  'PerGB2018'
  'Free'
]
)
@description('The Log AnalyticsWorkspace SKU - see https://learn.microsoft.com/en-us/azure/azure-monitor/logs/cost-logs')
param laSKU string = 'PerGB2018'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: name
  location: location
  tags: tags
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: laSKU
    }
  })
}

output id string = logAnalytics.id
output name string = logAnalytics.name
