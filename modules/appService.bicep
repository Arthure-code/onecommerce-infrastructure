
param appPlanName string
param location string 
param webAppNames array
param NiveauPlan string
param tagApplication string

resource servicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appPlanName
  location: location
  sku: {
    name: NiveauPlan == 'Dev' ? 'F1' : NiveauPlan == 'Test' ? 'B1' : 'S1'     
  }
  tags: {
    Application: tagApplication
  }
}

resource webApp 'Microsoft.Web/sites@2023-01-01' = [for webAppName in webAppNames: {

    name: 'webapp-${webAppName}-${substring(uniqueString(resourceGroup().id, webAppName), 0, 4)}'
    location: location
    properties: {
      serverFarmId: servicePlan.id
    }
    tags: {
      Application: tagApplication
    }
  }
]

resource stagingSlot 'Microsoft.Web/sites/slots@2023-01-01' = [ for i in range(0, length(webAppNames)): if (NiveauPlan == 'Prod') {

    name: 'staging'
    location: location
    parent: webApp[i]
    properties: {
      serverFarmId: servicePlan.id
    }
    tags: {
      Application: tagApplication
    }
  }
]

resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (NiveauPlan == 'Prod') {

  name: 'autoscale-${appPlanName}'
  location: location
  properties: {
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
    targetResourceUri: servicePlan.id
  }
}











// resource autoscale 'Microsoft.Insights/autoscalesettings@2022-10-01' = if (NiveauPlan == 'Prod') {
  
//   name: 'autoscale-${appPlanName}'
//   location: location
//   properties: {
//     profiles: [
//       {
//         name: 'defaultProfile'
//         capacity: {
//           minimum: '1'
//           maximum: '2'
//           default: '1'
//         }
//         rules: [
//           {
//             metricTrigger: {
//               metricName: 'CpuPercentage'
//               metricResourceUri: servicePlan.id
//               operator: 'GreaterThan'
//               threshold: 70
//               timeGrain: 'PT1M'
//               statistic: 'Average'
//               timeWindow: 'PT5M'
//               timeAggregation: 'Average'
//             }
//             scaleAction: {
//               direction: 'Increase'
//               type: 'ChangeCount'
//               value: '1'
//               cooldown: 'PT5M'
//             }
//           }
//         ]
//       }
//     ]
//     targetResourceUri: servicePlan.id
//   }
// }
