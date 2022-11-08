# Web Api Using Redis Demo

This application is an example web api that is using Azure Cache for Redis as the data store.

## Description

This project was created initially by using the Redis quickstart on the Microsoft learn site:  [Quickstart: Use Azure Cache for Redis with an ASP.NET Core web app](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-web-app-aspnet-core-howto).  Once the connection was established, then I modified the repo to create the infrastructure (iac folder) using a GitHub actions workflow (`deploy-app-service.yml`).  The api will `GET` and `POST` an `Employee` object using the Redis cache as the data store. See workflow section below for more specifics on the workflow and see the Infrastructure section for specifics on the infrastructure used

## Badges

[![Trigger app service deployment](https://github.com/anotherRedbeard/redis-cache-web-api/actions/workflows/deploy-app-service.yml/badge.svg)](https://github.com/anotherRedbeard/redis-cache-web-api/actions/workflows/deploy-app-service.yml)

## How to use

This is meant to be a repo that you can clone and use as you like.  The only thing you will need to change is the variables in the `deploy-app-service.yml` workflow.  They will be in the `env` section of the workflow.  There will need to change to match the resource names you would like to use in your Azure Subscription.

### Requirements

- **Azure Subscription**
- **This repo cloned in your own GitHub repo**
- **Service principle with contributor access to the subscription created as a GitHub Secret**
  - This is only so you can create your resource group at the subscription level, if you don't want to give your service principle that kind of access you will need to have another way to create the resource group and then you can remove that step from the workflow
  - The credentials for this service principle need to be stored according to this document:  [Service Principal Secret](https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure?tabs=azure-portal%2Clinux#use-the-azure-login-action-with-a-service-principal-secret)
  - I have used the name `AZURE_CREDENTIALS` for the secret 

## Workflow

The workflow has 3 separate stages: build-infra, build, deploy

1. build-infra
    - Uses a shared workflow that accepts the variables that were exposed as environment variables in the first stage to create the required infrastructure you need for the App Service using Redis as the data store.  These actions are idempotent so they can be run multiple times.
2. build
    - Builds, publishes, and creates the artifact to be deployed in the next step
3. deploy
    - Uses the artifact that was created in the build step and deploys it to the app service.
    - There is one additional step that will get the app service name from the deployment to demonstrate how you could use that if you didn't want to use the variable

## Infrastructure

This is a list of all the bicep templates used in the *build-infra* section of the workflow.  I've also included a short description of either the resource or how we are using it in this repo.

- **iac/app-service-with-redis.bicep**
  - Azure App Service Plan
    - Environment to contain the app service
  - Azure App Service
    - App service to host the API
  - Application Insights
    - App performance monitoring for the api
  - User-defined Managed Identity
    - Managed identity (service principal) that is used to be the identity of the app service.  This is used to provide RBAC to the key vault from the app service using the `Key Vault Secrets User` role.
  - Azure Cache for Redis
    - Redis implementation, this is the data store we are using for this demo
- **iac/key-vault.bicep**
  - Key Vault
    - Holds the secrets that will be used by the app service, check bicep file to see how these are linked together.  Since we are using a user-defined managed identity we had to set the `keyVaultReferenceIdentity` property on the app service.  See this [document](https://learn.microsoft.com/en-us/azure/app-service/app-service-key-vault-references?tabs=azure-cli#access-vaults-with-a-user-assigned-identity) for more info.
- **iac/log-analytics-ws.bicep**
  - Log Analytics Workspace
    - Holds log data
- **iac/main-deploy-app-service.bicep**
  - This is the main bicep file that pulls in the other files as modules and accepts the input parameters to create all the infrastructure needed to run this demo
