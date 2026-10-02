using 'main.bicep'

// A development deployment: free App Service plans, no staging slot, no
// autoscale. The password is not here. It is read from the environment at
// deployment time, so this file can be committed as it stands.
param location = 'canadacentral'
param environmentLevel = 'Dev'
param sqlServerName = 'onecommerce'
param sqlAdminLogin = 'onecommerceadmin'
param sqlAdminPassword = readEnvironmentVariable('SQL_ADMIN_PASSWORD')
param storageNameSeed = 'onefichiers'
