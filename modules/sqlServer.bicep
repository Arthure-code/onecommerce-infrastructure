metadata description = 'The SQL server, the elastic pool its databases share, the single firewall range allowed in, and the databases themselves.'

@description('Name of the server, without its srv- prefix.')
param sqlServerName string

@description('Region the server and its databases are created in.')
param location string

@description('Administrator account of the server.')
param sqlAdminLogin string

@description('Administrator password. Never written down, never returned.')
@secure()
@minLength(10)
@maxLength(20)
param sqlAdminPassword string

@description('Databases to create in the pool, without their db- prefix.')
param databaseNames array

@description('First address allowed to reach the server.')
param allowedIpFrom string

@description('Last address allowed to reach the server.')
param allowedIpTo string

@description('Value of the Application tag every resource carries.')
param tagApplication string

// A Basic pool stops at 5 DTU per database. Standard is the first tier
// that reaches the 50 and 200 set below.
var poolTier = 'Standard'
var poolCapacity = 200
var databaseMinCapacity = 50
var databaseMaxCapacity = 200

var tags = {
  Application: tagApplication
}

resource sqlServer 'Microsoft.Sql/servers@2025-01-01' = {
  name: 'srv-${sqlServerName}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
}

resource firewallRule 'Microsoft.Sql/servers/firewallRules@2025-01-01' = {
  parent: sqlServer
  name: 'AllowedIpRange'
  properties: {
    startIpAddress: allowedIpFrom
    endIpAddress: allowedIpTo
  }
}

resource azureServicesRule 'Microsoft.Sql/servers/firewallRules@2025-01-01' = {
  parent: sqlServer
  name: 'AllowAllWindowsAzureIps'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2025-01-01' = {
  parent: sqlServer
  name: 'pool-${sqlServerName}'
  location: location
  sku: {
    name: '${poolTier}Pool'
    tier: poolTier
    capacity: poolCapacity
  }
  tags: tags
  properties: {
    perDatabaseSettings: {
      minCapacity: databaseMinCapacity
      maxCapacity: databaseMaxCapacity
    }
  }
}

module databases 'sqlDatabase.bicep' = [for databaseName in databaseNames: {
  name: 'db-${databaseName}'
  params: {
    location: location
    sqlServerName: sqlServer.name
    elasticPoolId: elasticPool.id
    databaseName: databaseName
    tagApplication: tagApplication
  }
}]

@description('Name the server was given, prefix included.')
output sqlServerNameCreated string = sqlServer.name

@description('Address the applications connect to.')
output sqlServerFqdn string = sqlServer.properties.fullyQualifiedDomainName

@description('Name the pool was given, prefix included.')
output elasticPoolNameCreated string = elasticPool.name
