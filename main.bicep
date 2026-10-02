
@allowed([
  'CanadaCentral'
  'CanadaEast'
])
param location string

@allowed([
  'Dev'
  'Test'
  'Prod'
])
param NiveauPlan string

param applicationName string = 'OneCommerce'

param sqlServerName string
param sqlAdminLogin string
@secure()
@minLength(10)
@maxLength(20)
param sqlAdminPwd string

param storageName string

var appServiceGroups = [
  {
    appPlanName: 'Onecommerce-plan-1'
    webAppNames: [
      'OneCommerceMVC'
      'OneProduitAPI'
    ]
  }
  {
    appPlanName: 'Onecommerce-plan-2'
    webAppNames: [
      'OneFichiersAPI'
      'OneCommandesAPI'
      'OneFideliteAPI'
    ]
  }
]

var databases = [
  'Produits'
  'Commandes'
  'Fidelite'
]


module webApps 'modules/appService.bicep' = [ for group in appServiceGroups: {
    name: group.appPlanName
    params: {
      location: location
      appPlanName: 'sp-${group.appPlanName}'
      webAppNames: group.webAppNames
      NiveauPlan: NiveauPlan
      tagApplication: applicationName
    }
  }
]

resource sqlServer 'Microsoft.Sql/servers@2021-11-01' = {
  name: 'srv-${sqlServerName}'
  location: location
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPwd
    version: '12.0'
  }
  tags: {
    Application: applicationName
  }
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2021-11-01' = {
  name: 'AllowedIPRange'
  parent: sqlServer
  properties: {
    startIpAddress: '100.0.0.1'
    endIpAddress: '100.10.255.255'
  }
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2021-11-01' = {
  name: 'pool-${sqlServerName}'
  parent: sqlServer
  location: location
  sku: {
    name: 'StandardPool'
    tier: 'Standard'
    capacity: 200
  }
  properties: {
    perDatabaseSettings: {
      minCapacity: 50
      maxCapacity: 200
    }
  }
  tags: {
    Application: applicationName
  }
}


module sqlDatabases 'modules/sqlDatabase.bicep' = [ for dbName in databases: {
    name: 'db-${dbName}'
    params: {
      location: location
      sqlServerName: sqlServer.name
      elasticPoolName: elasticPool.name
      databaseName: dbName
      tagApplication: applicationName
    }
  }
]


resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'stone${uniqueString(resourceGroup().id, storageName)}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_RAGRS'
  }
  tags: {
    Application: applicationName
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource imagesContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: 'images'
  parent: blobService
  properties: {
    publicAccess: 'None'
  }
}

resource queueService 'Microsoft.Storage/storageAccounts/queueServices@2023-01-01' = {
  name: 'default'
  parent: storageAccount
}

resource commandQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2023-01-01' = {
  name: 'q-commande'
  parent: queueService
}
