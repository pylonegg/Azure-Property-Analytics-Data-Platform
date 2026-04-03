targetScope = 'subscription'

param namePrefix string
param location string = 'uksouth'
param tags object = {
  application :'networking'
}

module networking 'm_networking.bicep' = {
  params: {
    location:  location
    namePrefix: namePrefix
    tags: tags
    }
}


module governance 'm_governance.bicep' = {
  params: {
    location:  location
    namePrefix: namePrefix
    tags: tags
    }
}

/*

module data 'm_data.bicep' = {
  params: {
    location:  location
    namePrefix: namePrefix
    tags: tags
    }
}

module monitoring 'm_monitoring.bicep' = {
  params: {
    location:  location
    namePrefix: namePrefix
    tags: tags
    }
}
*/
