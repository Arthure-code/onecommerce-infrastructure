metadata description = 'One database inside an elastic pool. Its compute is the pool\'s, so it carries no size of its own.'

@description('Region the database is created in.')
param location string

@description('Name of the server that hosts the database, prefix included.')
param sqlServerName string

@description('Identifier of the pool the database draws its compute from.')
param elasticPoolId string

@description('Name of the database, without its db- prefix.')
param databaseName string

@description('Value of the Application tag every resource carries.')
param tagApplication string

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' existing = {
  name: sqlServerName
}

resource database 'Microsoft.Sql/servers/databases@2025-01-01' = {
  parent: sqlServer
  name: 'db-${databaseName}'
  location: location
  sku: {
    name: 'ElasticPool'
    tier: 'Standard'
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Application: tagApplication
  }
  properties: {
    elasticPoolId: elasticPoolId
  }
}

@description('Name the database was given, prefix included.')
output databaseNameCreated string = database.name
