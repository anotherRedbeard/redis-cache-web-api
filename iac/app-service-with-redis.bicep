param webAppName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param appServName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'DOTNETCORE|6.0' // The runtime stack of web app
param location string = resourceGroup().location // Location for all resources
param logwsid string
param startupCommand string = 'dotnet myapp.dll' // The runtime startup command
param redisCacheName string = 'redisCache-${uniqueString(resourceGroup().id)}'
param enableNonSslPort bool = false
param redisCacheSKU string = 'Standard'
param redisCacheFamily string = 'C'
param redisCacheCapacity int = 1
var appServicePlanName = toLower('red-AppServicePlan-${appServName}')
var appInsightsName = toLower('red-AppInsights-${webAppName}')
var webSiteName = toLower('red-webApp-${webAppName}')
param keyValueName string
// variables
var redisKeySecretName = toLower('${redisCacheName}-access-key')
var managedIdentityName = toLower('${redisCacheName}-managed-id')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

// Create application insights
resource appi 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Bluefield'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    Request_Source: 'rest'
    RetentionInDays: 30
    WorkspaceResourceId: logwsid
  }
 }

 resource redisCache 'Microsoft.Cache/Redis@2020-06-01' = {
  name: redisCacheName
  location: location
  properties: {
    enableNonSslPort: enableNonSslPort
    minimumTlsVersion: '1.2'
    redisVersion: '6.0'
    sku: {
      capacity: redisCacheCapacity
      family: redisCacheFamily
      name: redisCacheSKU
    }
  }
}

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appCommandLine: startupCommand
      appSettings: [
        {
          name: 'CacheConnection'
          value: kv.outputs.secretUri
        }
        {
          name: 'WEBSITE_ENABLE_SYNC_UPDATE_SITE'
          value: 'true'
        }
      ]
    }
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${msi.id}': {}
    }
  }
}

// Managed Identity resources
resource msi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: managedIdentityName
  location: location
}

// Create KeyVault
module kv 'key-vault.bicep' = {
  name: 'KeyVaultDeployment'
  params: {
    keyVaultName: keyValueName
    location: location
    objectId: msi.properties.principalId
    secretName: redisKeySecretName
    secretValue: '${redisCacheName}.redis.cache.windows.net,abortConnect=false,ssl=true,password=${redisCache.listKeys().primaryKey}'
  }
}

// Return the app service name and farm name
output appName string = appService.name
output aspName string = appServicePlan.name
output appInsightsName string = appi.name
