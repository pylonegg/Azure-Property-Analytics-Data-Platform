targetScope = 'subscription'

@description('Location for all resources')
param location string

@description('Base name prefix for resource groups and resources')
param namePrefix string

param tags object



// RESOURCE GROUPS  ----------------------------------------
resource rgMgmt 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-mgmt-rg'
  location: location
}


// NETWORKING - VNET HUB ---------------------------------
module HubVnet'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${namePrefix}-hub-vnet'
  scope: rgMgmt
  params: {
    addressPrefixes: ['10.0.0.0/16']
    name: '${namePrefix}-vnet-hub'
    location: location
    subnets: [
      {
        name: 'subnet-bastion'
        addressPrefix: '10.0.1.0/24'
      }
      {
        name: 'subnet-firewall'
        addressPrefix: '10.0.2.0/24'
      }
      {
        name: 'subnet-private-endpoints'
        addressPrefix: '10.0.3.0/24'
      }
    ]
    peerings: [
      {
        remoteVirtualNetworkResourceId: SpokeVnetData.outputs.resourceId
        name: 'Hub-to-SpokeVnetData'
        allowForwardedTraffic: true
        allowGatewayTransit: true
      }
      {
        remoteVirtualNetworkResourceId: SpokeVnetBI.outputs.resourceId
        name: 'Hub-to-SpokeVnetBI'
        allowForwardedTraffic: true
        allowGatewayTransit: true
      }
      {
        remoteVirtualNetworkResourceId: SpokeVnetApp.outputs.resourceId
        name: 'Hub-to-SpokeVnetApp'
        allowForwardedTraffic: true
        allowGatewayTransit: true
      }
    ]
    tags: tags
  }
}

// NETWORKING - VNET - SPOKES -----------------------------------
module SpokeVnetData 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${namePrefix}-vnet-data'
  scope: rgMgmt
  
  params: {
    tags: tags
    addressPrefixes: ['10.1.0.0/16']
    name: '${namePrefix}-vnet-data'
    location: location
    subnets: [
    ]
  }
}

module SpokeVnetBI 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${namePrefix}-vnet-bi'
  scope: rgMgmt
  params: {
    tags: tags
    addressPrefixes: ['10.2.0.0/16']
    name: '${namePrefix}-vnet-bi'
    location: location
    subnets: [
    ]
    
  }
}

module SpokeVnetApp 'br/public:avm/res/network/virtual-network:0.7.1' = {
  name: '${namePrefix}-vnet-app'
  scope: rgMgmt
  params: {
    tags: tags
    addressPrefixes: ['10.3.0.0/16']
    name: '${namePrefix}-vnet-app'
    location: location
    subnets: [
    ]
  }
}


/*

// NETWORKING - SECURITY GROUPS  -----------------------------------

// NETWORKING - FIREWALL  -----------------------------------
module firewall 'br/public:avm/res/network/azure-firewall:0.10.0' = {
  name: '${namePrefix}-fw'
  scope: rgMgmt
  params: {
    name: '${namePrefix}-fw'
    azureSkuTier: 'Standard'
    additionalPublicIpConfigurations: [
      {
        name: 'fw-ipconfig'
        properties: {
          subnet: { id: '${HubVnet}/subnets/subnet-firewall' }
          publicIPAddress: null
        }
      }
    ]
  }

}


// NETWORKING - ROUTE TABLE  -----------------------------------
module RouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  name: '${namePrefix}-rt'
  scope: rgMgmt
  params: {
    name: '${namePrefix}-rt'
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

module pe 'br/public:avm/res/network/private-endpoint:0.12.0' = {
  name: '${namePrefix}-blob-pe'
  scope: rgMgmt
  params: {
    tags: tags
    name: '${namePrefix}-blob-pe'
    subnetResourceId: '${HubVnet}/subnets/subnet-private-endpoints'
        privateLinkServiceConnections: [
  //    {
  //      name: '${prefix}-${targetResourceAlias}-pls'
  //      properties: {
  //        privateLinkServiceId: targetResourceId
  //        groupIds: ['blob']
  //      }
  //    }
    ]
  }
}


*/
