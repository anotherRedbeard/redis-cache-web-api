// =========== main.bicep ===========
@minLength(1)
@description('The location of the app service')
param location string = resourceGroup().location

@maxLength(10)
@minLength(2)
@description('The name of the app service to create.')
param app_service_postfix string 

@maxLength(10)
@minLength(2)
@description('The name of the app service plan to create.')
param app_service_plan_postfix string 

@maxLength(10)
@minLength(2)
@description('The name of the redis cache.')
param redis_cache_name string 

@maxLength(40)
@minLength(2)
@description('The version of the stack you are running.')
param stack_version string 

@maxLength(200)
@minLength(2)
@description('The startup command you want to use in the stack settings.')
param startup_command string 

@allowed([
  'B1'
])
@description('The name of the app service sku.')
param app_service_sku string

@description('Specify the name of the Azure Redis Cache to create.')
param redisCacheName string = 'redisCache-${uniqueString(resourceGroup().id)}'
@description('Specify a boolean value that indicates whether to allow access via non-SSL ports.')
param enableNonSslPort bool = false
@description('Specify the pricing tier of the new Azure Redis Cache.')
@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param redisCacheSKU string = 'Standard'

@description('Specify the family for the sku. C = Basic/Standard, P = Premium.')
@allowed([
  'C'
  'P'
])
param redisCacheFamily string = 'C'

@description('Specify the size of the new Azure Redis Cache instance. Valid values: for C (Basic/Standard) family (0, 1, 2, 3, 4, 5, 6), for P (Premium) family (1, 2, 3, 4)')
@allowed([
  0
  1
  2
  3
  4
  5
  6
])
param redisCacheCapacity int = 1

// =================================

// Create Log Analytics workspace
module logws './log-analytics-ws.bicep' = {
  name: 'LogWorkspaceDeployment'
  params: {
    name: app_service_plan_postfix
    location: location
  }
}

// Create Redis cache
module redis './redis-cache.bicep' = {
  name: 'RedisCacheDeployment'
  params: {
    redisCacheName: redis_cache_name
    location: location

  }
}

// Create app service
module appService './app-service.bicep' = {
  name: 'AppServiceDeployment'
  params: {
    webAppName: app_service_postfix
    appServName: app_service_plan_postfix
    sku: app_service_sku
    linuxFxVersion: stack_version
    startupCommand: startup_command
    location: location
    logwsid: logws.outputs.id
    redisCacheName: redisCacheName
    redisCacheCapacity: redisCacheCapacity
    redisCacheFamily: redisCacheFamily
    redisCacheSKU: redisCacheSKU
    enableNonSslPort: enableNonSslPort
  }
}

output appServiceName string = appService.outputs.appName
output appServicePlanName string = appService.outputs.aspName
