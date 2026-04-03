This is a serious enterprise-grade architecture, so the Bicep should be modular, not one giant file. I’ll give you a clean, production-style Bicep structure that maps directly to your diagram:

⸻

🧱 Recommended Bicep Structure

/bicep
 ├── main.bicep
 ├── networking/
 │    ├── hubVnet.bicep
 │    ├── spokeDataVnet.bicep
 │    ├── spokeBiVnet.bicep
 │    ├── nsg.bicep
 │    └── privateEndpoints.bicep
 ├── data/
 │    ├── adls.bicep
 │    ├── databricks.bicep
 │    ├── dataFactory.bicep
 │    └── eventHub.bicep
 ├── governance/
 │    ├── purview.bicep
 │    ├── keyVault.bicep
 ├── analytics/
 │    ├── powerbi.bicep (placeholder)
 │    └── synapseServerless.bicep
 ├── monitoring/
 │    ├── logAnalytics.bicep
 │    └── monitor.bicep


⸻

🚀 MAIN ENTRY (main.bicep)

This wires everything together:

param location string = 'eastus'
param prefix string = 'data-platform'

// Resource Group scoped deployment assumed

module hub './networking/hubVnet.bicep' = {
  name: 'hubVnet'
  params: {
    location: location
    prefix: prefix
  }
}

module dataSpoke './networking/spokeDataVnet.bicep' = {
  name: 'dataSpoke'
  params: {
    location: location
    prefix: prefix
    hubVnetId: hub.outputs.vnetId
  }
}

module biSpoke './networking/spokeBiVnet.bicep' = {
  name: 'biSpoke'
  params: {
    location: location
    prefix: prefix
    hubVnetId: hub.outputs.vnetId
  }
}

module adls './data/adls.bicep' = {
  name: 'adls'
  params: {
    location: location
    prefix: prefix
  }
}

module keyVault './governance/keyVault.bicep' = {
  name: 'kv'
  params: {
    location: location
    prefix: prefix
  }
}

module databricks './data/databricks.bicep' = {
  name: 'databricks'
  params: {
    location: location
    prefix: prefix
    vnetId: dataSpoke.outputs.vnetId
  }
}

module adf './data/dataFactory.bicep' = {
  name: 'adf'
  params: {
    location: location
    prefix: prefix
  }
}

module purview './governance/purview.bicep' = {
  name: 'purview'
  params: {
    location: location
    prefix: prefix
  }
}

module logAnalytics './monitoring/logAnalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    prefix: prefix
  }
}


⸻

🌐 HUB VNET (networking/hubVnet.bicep)

param location string
param prefix string

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-hub-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.0.3.0/24'
        }
      }
    ]
  }
}

output vnetId string = vnet.id


⸻

📦 DATA SPOKE (networking/spokeDataVnet.bicep)

param location string
param prefix string
param hubVnetId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: '${prefix}-data-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'databricks'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
      {
        name: 'private-endpoints'
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
    ]
  }
}

// Peering
resource peeringToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-05-01' = {
  name: '${vnet.name}/to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnetId
    }
    allowForwardedTraffic: true
    allowVirtualNetworkAccess: true
  }
}

output vnetId string = vnet.id


⸻

🗄️ ADLS GEN2 (data/adls.bicep)

param location string
param prefix string

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: toLower('${prefix}adls')
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    isHnsEnabled: true
  }
}

resource bronze 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storage.name}/default/bronze'
}

resource silver 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storage.name}/default/silver'
}

resource gold 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${storage.name}/default/gold'
}


⸻

🔥 DATABRICKS (data/databricks.bicep)

param location string
param prefix string
param vnetId string

resource workspace 'Microsoft.Databricks/workspaces@2023-02-01' = {
  name: '${prefix}-dbw'
  location: location
  sku: {
    name: 'premium'
  }
  properties: {
    parameters: {
      customVirtualNetworkId: {
        value: vnetId
      }
      enableNoPublicIp: {
        value: true
      }
    }
  }
}


⸻

🔐 KEY VAULT (governance/keyVault.bicep)

param location string
param prefix string

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: '${prefix}-kv'
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    accessPolicies: []
  }
}


⸻

🧠 PURVIEW (governance/purview.bicep)

param location string
param prefix string

resource purview 'Microsoft.Purview/accounts@2023-05-01' = {
  name: '${prefix}-purview'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}


⸻

📊 LOG ANALYTICS (monitoring/logAnalytics.bicep)

param location string
param prefix string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${prefix}-law'
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}


Perfect — let’s complete your enterprise-grade Bicep architecture by adding the missing modules:

We’ll cover:
	1.	Private Endpoints
	2.	Azure Firewall + UDRs
	3.	Event Hub
	4.	API Management
	5.	Power BI placeholder (since it’s mostly manual)
	6.	Feature Store placeholder (Databricks integration)

I’ll provide modular Bicep files that integrate cleanly with your existing structure.

⸻

1️⃣ Private Endpoints (networking/privateEndpoints.bicep)

param location string
param prefix string
param vnetId string
param subnetName string = 'private-endpoints'
param targetResourceId string
param targetResourceAlias string = 'storage'

resource pe 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: '${prefix}-${targetResourceAlias}-pe'
  location: location
  properties: {
    subnet: {
      id: '${vnetId}/subnets/${subnetName}'
    }
    privateLinkServiceConnections: [
      {
        name: '${prefix}-${targetResourceAlias}-pls'
        properties: {
          privateLinkServiceId: targetResourceId
          groupIds: ['blob']
        }
      }
    ]
  }
}

output privateEndpointId string = pe.id

Tip: Create one PE per service (ADLS, SQL, Event Hub, etc.) and reference vnetId and subnet.

⸻

2️⃣ Azure Firewall + UDRs (networking/firewall.bicep)

param location string
param prefix string
param hubVnetId string
param hubFirewallSubnet string = 'AzureFirewallSubnet'

resource firewall 'Microsoft.Network/azureFirewalls@2023-05-01' = {
  name: '${prefix}-fw'
  location: location
  properties: {
    sku: { name: 'AZFW_VNet', tier: 'Standard' }
    ipConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: { id: '${hubVnetId}/subnets/${hubFirewallSubnet}' }
          publicIPAddress: null
        }
      }
    ]
  }
}

output firewallId string = firewall.id

Optional: UDR Example

param routeTableName string = '${prefix}-rt'

resource rt 'Microsoft.Network/routeTables@2023-05-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: 'default-to-fw'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.2.4' // example firewall private IP
        }
      }
    ]
  }
}


⸻

3️⃣ Event Hub (data/eventHub.bicep)

param location string
param prefix string

resource namespace 'Microsoft.EventHub/namespaces@2022-10-01' = {
  name: '${prefix}-eh-ns'
  location: location
  sku: { name: 'Standard', tier: 'Standard', capacity: 1 }
  properties: { isAutoInflateEnabled: true, maximumThroughputUnits: 5 }
}

resource hub 'Microsoft.EventHub/namespaces/eventhubs@2022-10-01' = {
  name: '${namespace.name}/raw-events'
  properties: { partitionCount: 4, messageRetentionInDays: 7 }
}

output eventHubNamespace string = namespace.name
output eventHubName string = hub.name


⸻

4️⃣ API Management (apiManagement.bicep)

param location string
param prefix string
param publisherEmail string = 'admin@example.com'
param publisherName string = 'Contoso'

resource apim 'Microsoft.ApiManagement/service@2023-01-01' = {
  name: '${prefix}-apim'
  location: location
  sku: { name: 'Developer', capacity: 1 }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkType: 'External' // or 'Internal' for private
  }
}

output apimId string = apim.id

Tip: Use External for public APIs or Internal to integrate with your VNets.

⸻

5️⃣ Power BI Placeholder (analytics/powerbi.bicep)

Power BI is mostly manual or via REST API, so we create a placeholder:

param prefix string

output powerBIPlaceholder string = 'Power BI deployment to be configured manually or via REST API'


⸻

6️⃣ Feature Store Placeholder (data/featureStore.bicep)

param prefix string
param databricksWorkspaceId string

output featureStorePlaceholder string = 'Feature Store will be created inside Databricks workspace: ${databricksWorkspaceId}'

Tip: This lets you track dependencies in Bicep while provisioning Databricks workspaces.

⸻

✅ Integration in main.bicep

module peAdls './networking/privateEndpoints.bicep' = {
  name: 'peAdls'
  params: { location: location, prefix: prefix, vnetId: dataSpoke.outputs.vnetId, targetResourceId: adls.outputs.storageId }
}

module firewall './networking/firewall.bicep' = {
  name: 'firewall'
  params: { location: location, prefix: prefix, hubVnetId: hub.outputs.vnetId }
}

module eventHub './data/eventHub.bicep' = {
  name: 'eventHub'
  params: { location: location, prefix: prefix }
}

module apim './networking/apiManagement.bicep' = {
  name: 'apim'
  params: { location: location, prefix: prefix }
}

module featureStore './data/featureStore.bicep' = {
  name: 'featureStore'
  params: { prefix: prefix, databricksWorkspaceId: databricks.outputs.workspaceId }
}

module powerBI './analytics/powerbi.bicep' = {
  name: 'powerBI'
  params: { prefix: prefix }
}

