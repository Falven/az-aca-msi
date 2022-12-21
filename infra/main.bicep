param projectName string
param environment string
param location string = resourceGroup().location
param secretName string
@secure()
param secretValue string
param registryName string
param azCliContainer string
param dotnetContainer string

module keyVault 'keyvault.bicep' = {
  name: 'keyVault-deployment'
  params: {
    name: projectName
    environment: environment
    location: location
    secrets: [
      {
        name: secretName
        value: secretValue
      }
    ]
  }
}

module containerEnv 'container-env.bicep' = {
  name: 'containerEnv-deployment'
  params: {
    name: projectName
    environment: environment
    location: location
  }
}

module azCliContainerApp 'container-app.bicep' = {
  name: 'containerApp-azcli-deployment'
  params: {
    name: 'ca-azcli-${environment}-001'
    location: location
    containerEnvironmentId: containerEnv.outputs.id
    registryName: registryName
    containerImage: azCliContainer
    command: [ 'tail', '-f', '/dev/null' ]
    appSettings: [
      {
        name: 'APPSETTING_WEBSITE_SITE_NAME'
        value: 'azcli-workaround'
      }
    ]
  }
}

module azCliRbac 'rbac.bicep' = {
  name: 'rbac-azcli-deployment'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    serviceName: azCliContainerApp.outputs.serviceName
    servicePrincipalId: azCliContainerApp.outputs.principalId
  }
}

module dotnetContainerApp 'container-app.bicep' = {
  name: 'containerApp-dotnet-deployment'
  params: {
    name: 'ca-dotnet-${environment}-001'
    location: location
    containerEnvironmentId: containerEnv.outputs.id
    registryName: registryName
    containerImage: dotnetContainer
    command: [ 'tail', '-f', '/dev/null' ]
  }
}

module dotnetRbac 'rbac.bicep' = {
  name: 'rbac-dotnet-deployment'
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    serviceName: dotnetContainerApp.outputs.serviceName
    servicePrincipalId: dotnetContainerApp.outputs.principalId
  }
}
