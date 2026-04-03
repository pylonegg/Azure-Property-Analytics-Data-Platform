
param location string
param prefix string
param vnetId string

// ==============================
// EVENT HUB NAMESPACE
// ==============================
module eventHubNs 'br/public:avm/res/event-hub/namespace:0.6.1' = {
  name: '${prefix}-eh-ns'
  params: {
    name: '${prefix}-eh-ns'
    location: location

    skuName: 'Standard'
    skuTier: 'Standard'
    capacity: 1

    isAutoInflateEnabled: true
    maximumThroughputUnits: 5
  }
}

// ==============================
// EVENT HUB
// ==============================
module eventHub 'br/public:avm/res/event-hub/event-hub:0.5.1' = {
  name: '${prefix}-eh'
  params: {
    name: 'raw-events'
    namespaceResourceId: eventHubNs.outputs.resourceId

    partitionCount: 4
    messageRetentionInDays: 7
  }
}

// ==============================
// STORAGE (ADLS GEN2)
// ==============================
var storageName = toLower('${prefix}adls')

module storage 'br/public:avm/res/storage/storage-account:0.9.2' = {
  name: storageName
  params: {
    name: storageName
    location: location

    skuName: 'Standard_LRS'
    kind: 'StorageV2'

    isHnsEnabled: true

    blobServices: {
      containers: [
        {
          name: 'bronze'
        }
        {
          name: 'silver'
        }
        {
          name: 'gold'
        }
      ]
    }
  }
}

// ==============================
// DATABRICKS (VNET INJECTED)
// ==============================
module databricks 'br/public:avm/res/databricks/workspace:0.5.1' = {
  name: '${prefix}-dbw'
  params: {
    name: '${prefix}-dbw'
    location: location

    skuName: 'premium'

    parameters: {
      customVirtualNetworkId: vnetId
      enableNoPublicIp: true
    }
  }
}

// ==============================
// DATA FACTORY
// ==============================
module dataFactory 'br/public:avm/res/data-factory/factory:0.6.1' = {
  name: '${prefix}-adf'
  params: {
    name: '${prefix}-adf'
    location: location
  }
}

// ==============================
// OUTPUTS
// ==============================
output eventHubNamespace string = eventHubNs.outputs.name
output eventHubName string = eventHub.outputs.name

output storageAccountName string = storage.outputs.name
output databricksWorkspaceName string = databricks.outputs.name
output dataFactoryName string = dataFactory.outputs.name
