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

// Fifty DTU as a floor and two hundred as a ceiling, per database. A Basic
// pool stops at five DTU per database, so it cannot hold those numbers at
// all. Standard is the first tier where they exist, and the cheapest one.
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
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Enabled'
  }
  tags: tags
}

// One range, and nothing else. The rule that opens the server to every
// Azure service is deliberately absent.
resource firewallRule 'Microsoft.Sql/servers/firewallRules@2025-01-01' = {
  name: 'AllowedIpRange'
  parent: sqlServer
  properties: {
    startIpAddress: allowedIpFrom
    endIpAddress: allowedIpTo
  }
}

resource elasticPool 'Microsoft.Sql/servers/elasticPools@2025-01-01' = {
  name: 'pool-${sqlServerName}'
  parent: sqlServer
  location: location
  sku: {
    name: '${poolTier}Pool'
    tier: poolTier
    capacity: poolCapacity
  }
  properties: {
    perDatabaseSettings: {
      minCapacity: databaseMinCapacity
      maxCapacity: databaseMaxCapacity
    }
  }
  tags: tags
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
