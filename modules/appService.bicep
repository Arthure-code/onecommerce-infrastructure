metadata description = 'One App Service plan and the applications that share it, with a staging slot and an autoscale rule when the tier carries them.'

@description('Name of the plan, prefix included.')
param appPlanName string

@description('Region the plan and its applications are created in.')
param location string

@description('Applications placed on this plan. Each one gets its own App Service.')
param webAppNames array

@description('Environment level, which decides the pricing tier.')
@allowed([
  'Dev'
  'Test'
  'Prod'
])
param environmentLevel string

@description('Value of the Application tag every resource carries.')
param tagApplication string

var skuByLevel = {
  Dev: 'F1'
  Test: 'B1'
  Prod: 'S1'
}

// Deployment slots and autoscale exist from S1 upwards. Asking for them
// on a free plan fails the deployment.
var carriesSlots = environmentLevel == 'Prod'

var tags = {
  Application: tagApplication
}

resource servicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appPlanName
  location: location
  sku: {
    name: skuByLevel[environmentLevel]
  }
  tags: tags
}

resource webApp 'Microsoft.Web/sites@2025-03-01' = [for webAppName in webAppNames: {
  // uniqueString is derived from the resource group, so a second
  // deployment produces the same four characters.
  name: 'webapp-${webAppName}-${substring(uniqueString(resourceGroup().id, webAppName), 0, 4)}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
}]

// Bicep refuses a nested resource inside a for-expression, BCP160, so the
// configuration is attached to each application rather than declared in it.
resource authentification 'Microsoft.Web/sites/config@2025-03-01' = [for (webAppName, index) in webAppNames: {
  parent: webApp[index]
  name: 'authsettingsV2'
  properties: {
    globalValidation: {
      requireAuthentication: false
      unauthenticatedClientAction: 'AllowAnonymous'
    }
    platform: {
      enabled: false
    }
  }
}]

resource stagingSlot 'Microsoft.Web/sites/slots@2025-03-01' = [for (webAppName, index) in webAppNames: if (carriesSlots) {
  parent: webApp[index]
  name: 'staging'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  tags: tags
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
}]

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (carriesSlots) {
  name: 'autoscale-${appPlanName}'
  location: location
  tags: tags
  properties: {
    targetResourceUri: servicePlan.id
    profiles: [
      {
        name: 'defaultProfile'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: servicePlan.id
              operator: 'GreaterThan'
              threshold: 70
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: servicePlan.id
              operator: 'LessThan'
              threshold: 40
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

@description('Names the applications were given, random suffix included.')
output webAppNamesCreated array = [for (webAppName, index) in webAppNames: webApp[index].name]

@description('Addresses the applications answer on.')
output webAppHosts array = [for (webAppName, index) in webAppNames: webApp[index].properties.defaultHostName]
