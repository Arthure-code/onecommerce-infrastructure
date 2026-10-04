metadata description = 'Everything OneCommerce runs on in one resource group: two App Service plans and their five applications, a SQL server whose three databases share an elastic pool, and a storage account with a private container and a queue.'

@description('Region everything is created in. The two Canadian regions keep the data in the country.')
@allowed([
  'canadacentral'
  'canadaeast'
])
param location string

@description('Environment level. It decides the App Service tier, and with it the staging slot and the autoscale rule.')
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param environmentLevel string

@description('Name the Application tag carries on every resource.')
param applicationName string = 'OneCommerce'

@description('Name of the SQL server, without its srv- prefix.')
param sqlServerName string

@description('Administrator account of the SQL server.')
param sqlAdminLogin string

@description('Administrator password of the SQL server. It is asked for at deployment time and never stored here.')
@secure()
@minLength(10)
@maxLength(20)
param sqlAdminPassword string

@description('Seed of the storage account name. The name itself is derived from it and from the resource group.')
param storageNameSeed string

var appServiceGroups = [
  {
    planName: 'sp-OneCommerce-plan-1'
    webAppNames: [
      'OneCommerceMVC'
      'OneProduitAPI'
    ]
  }
  {
    planName: 'sp-OneCommerce-plan-2'
    webAppNames: [
      'OneFichiersAPI'
      'OneCommandesAPI'
      'OneFideliteAPI'
    ]
  }
]

var databaseNames = [
  'Produits'
  'Commandes'
  'Fidelite'
]

var allowedIpFrom = '100.0.0.1'
var allowedIpTo = '100.10.255.255'

module appServices 'modules/appService.bicep' = [for group in appServiceGroups: {
  name: group.planName
  params: {
    location: location
    appPlanName: group.planName
    webAppNames: group.webAppNames
    environmentLevel: environmentLevel
    tagApplication: applicationName
  }
}]

module sqlServer 'modules/sqlServer.bicep' = {
  name: 'sql-${sqlServerName}'
  params: {
    location: location
    sqlServerName: sqlServerName
    sqlAdminLogin: sqlAdminLogin
    sqlAdminPassword: sqlAdminPassword
    databaseNames: databaseNames
    allowedIpFrom: allowedIpFrom
    allowedIpTo: allowedIpTo
    tagApplication: applicationName
  }
}

module storage 'modules/storageAccount.bicep' = {
  name: 'storage-${storageNameSeed}'
  params: {
    location: location
    storageNameSeed: storageNameSeed
    containerName: 'images'
    queueName: 'q-commande'
    tagApplication: applicationName
  }
}

@description('Addresses the five applications answer on, plan by plan.')
output webAppHosts array = [for (group, index) in appServiceGroups: appServices[index].outputs.webAppHosts]

@description('Address the applications reach the databases at.')
output sqlServerFqdn string = sqlServer.outputs.sqlServerFqdn

@description('Name the storage account was given.')
output storageAccountName string = storage.outputs.storageAccountName
