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

// =================================

// Create Log Analytics workspace
module logws './log-analytics-ws.bicep' = {
  name: 'LogWorkspaceDeployment'
  params: {
    name: app_service_plan_postfix
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
  }
}

output appServiceName string = appService.outputs.appName
output appServicePlanName string = appService.outputs.aspName
