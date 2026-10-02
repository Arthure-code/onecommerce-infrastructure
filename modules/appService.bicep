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

// The three tiers the deployment offers. F1 is free and runs one instance,
// B1 is the first paid tier, S1 is the first one that carries deployment
// slots and autoscale.
var skuByLevel = {
  Dev: 'F1'
  Test: 'B1'
  Prod: 'S1'
}

// Slots and autoscale exist from S1 upwards. Asking for them on F1 fails
// the deployment rather than being quietly ignored.
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
  // Four characters drawn from the resource group, not from the clock: the
  // same deployment run twice gives the same name rather than a second
  // application.
  name: 'webapp-${webAppName}-${substring(uniqueString(resourceGroup().id, webAppName), 0, 4)}'
  location: location
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
  tags: tags
}]

resource stagingSlot 'Microsoft.Web/sites/slots@2025-03-01' = [for (webAppName, index) in webAppNames: if (carriesSlots) {
  name: 'staging'
  location: location
  parent: webApp[index]
  properties: {
    serverFarmId: servicePlan.id
    httpsOnly: true
    siteConfig: {
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
    }
  }
  tags: tags
}]

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (carriesSlots) {
  name: 'autoscale-${appPlanName}'
  location: location
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
            // One instance more above 70 % of processor.
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
            // And one instance less below 40 %, because a plan that only
            // ever grows keeps costing what it no longer needs.
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
  tags: tags
}

@description('Names the applications were given, random suffix included.')
output webAppNamesCreated array = [for (webAppName, index) in webAppNames: webApp[index].name]

@description('Addresses the applications answer on.')
output webAppHosts array = [for (webAppName, index) in webAppNames: webApp[index].properties.defaultHostName]
