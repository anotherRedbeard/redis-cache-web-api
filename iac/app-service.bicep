param webAppName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param appServName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'DOTNETCORE|6.0' // The runtime stack of web app
param location string = resourceGroup().location // Location for all resources
param logwsid string
param startupCommand string = 'dotnet myapp.dll' // The runtime startup command
var appServicePlanName = toLower('red-AppServicePlan-${appServName}')
var appInsightsName = toLower('red-AppInsights-${webAppName}')
var webSiteName = toLower('red-webApp-${webAppName}')

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

resource appService 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      appCommandLine: startupCommand
    }
  }
}

// Return the app service name and farm name
output appName string = appService.name
output aspName string = appServicePlan.name
output appInsightsName string = appi.name
