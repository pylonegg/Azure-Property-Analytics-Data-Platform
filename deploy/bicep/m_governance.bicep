targetScope = 'subscription'

param location string
param namePrefix string

param tags object


// RESOURCE GROUPS  ----------------------------------------
resource rgGovernance 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${namePrefix}-gov-rg'
  location: location
}
// KEY VAULT
module keyVault 'br/public:avm/res/key-vault/vault:0.10.0' = {
  name: '${namePrefix}-kv'
  scope: rgGovernance
  params: {
    tags: tags
    name: '${namePrefix}-kv'
    location: location
    sku: 'standard'
    enableRbacAuthorization: true
    enableSoftDelete: true
    publicNetworkAccess: 'Enabled'
  }
}

// PURVIEW ACCOUNT
module purview 'br/public:avm/res/purview/account:0.5.1' = {
  name: '${namePrefix}-purview'
  scope: rgGovernance
  params: {
    tags: tags
    name: '${namePrefix}-purview'
    location: location
  }
}





// ==============================
// OUTPUTS
// ==============================
output purviewName string = purview.outputs.name
output purviewId string = purview.outputs.resourceId

output keyVaultName string = keyVault.outputs.name
output keyVaultId string = keyVault.outputs.resourceId
