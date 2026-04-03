targetScope = 'subscription'

param location string
param namePrefix string
param tags object



// RESOURCE GROUPS  ----------------------------------------
resource rgMonitor 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-monitor-rg'
  location: location
  tags: tags
}


module logAnalytics 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  name: '${namePrefix}-law'
  scope: rgMonitor
  params: {
    tags: tags
    name: '${namePrefix}-law'
    location: location
    skuName: 'PerGB2018'
  }
}


module actionGroup 'br/public:avm/res/insights/action-group:0.3.0' = {
  name: '${namePrefix}-ag'
  scope: rgMonitor
  params: {
    tags: tags
    name: '${namePrefix}-ag'
    location: location

    groupShortName: 'ag01'

    emailReceivers: [
      {
        name: 'admin'
        emailAddress: 'admin@pylonegg.co.uk'
      }
    ]
  }
}
