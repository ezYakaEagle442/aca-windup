param name string
param location string = resourceGroup().location
param tags object = {}

@allowed([
  'CapacityReservation'
  'LACluster'
  'Basic'
]
)
@description('The Log AnalyticsWorkspace SKU - see https://learn.microsoft.com/en-us/azure/azure-monitor/logs/cost-logs')
param laSKU string = 'Basic'

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
