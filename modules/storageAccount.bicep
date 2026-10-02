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

// Read access geo-redundant: a second region keeps a copy that can still
// be read while the first one is down.
var redundancy = 'Standard_RAGRS'

var tags = {
  Application: tagApplication
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  // Account names are global and allow 24 lowercase characters at most.
  // uniqueString adds thirteen to the five of stone, which fits, and it
  // derives them from the resource group, so a second run keeps the name.
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
