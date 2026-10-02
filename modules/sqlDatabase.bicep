
param location string
param sqlServerName string
param elasticPoolName string
param databaseName string
param tagApplication string

resource database 'Microsoft.Sql/servers/databases@2021-11-01' = {
  name: '${sqlServerName}/db-${databaseName}'
  location: location
  sku: {
    name: 'ElasticPool'
  }
  properties: {
    elasticPoolId: resourceId('Microsoft.Sql/servers/elasticPools',
      sqlServerName,
      elasticPoolName
    )
  }
  tags: {
    Application: tagApplication
  }
}
