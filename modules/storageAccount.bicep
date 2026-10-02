metadata description = 'The storage account the file API writes to, with its private container and its queue.'

@description('Seed of the account name. The name itself is derived so that it stays unique across Azure.')
param storageNameSeed string

@description('Region the account is created in.')
param location string

@description('Name of the private container the images are written to.')
param containerName string

@description('Name of the queue the orders are posted to.')
param queueName string

@description('Value of the Application tag every resource carries.')
param tagApplication string

// Read access geo-redundant: a second region keeps a readable copy, which
// is what being able to read while a datacentre is down means.
var redundancy = 'Standard_RAGRS'

var tags = {
  Application: tagApplication
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  // Account names are global and allow 24 lowercase characters at most.
  // uniqueString gives thirteen from the resource group, which leaves the
  // stone prefix room and keeps the name the same on a second run.
  name: 'stone${uniqueString(resourceGroup().id, storageNameSeed)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: redundancy
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
  }
  tags: tags
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2026-04-01' = {
  name: 'default'
  parent: storageAccount
}

resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2026-04-01' = {
  name: containerName
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2026-04-01' = {
  name: 'default'
  parent: storageAccount
}

resource ordersQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2026-04-01' = {
  name: queueName
  parent: queueService
}

@description('Name the account was given.')
output storageAccountName string = storageAccount.name

@description('Address of the blob endpoint the applications read from.')
output blobEndpoint string = storageAccount.properties.primaryEndpoints.blob
