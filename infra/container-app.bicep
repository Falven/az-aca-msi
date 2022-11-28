param name string
param location string
param containerEnvironmentId string

param registryName string
param containerImage string
param command array = []
param appSettings array = []

resource registry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: registryName
  scope: resourceGroup()
}

resource containerApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: name
  location: location
  properties: {
    managedEnvironmentId: containerEnvironmentId
    configuration: {
      secrets: [
        {
          name: 'container-registry-password'
          value: registry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: registry.properties.loginServer
          username: registry.listCredentials().username
          passwordSecretRef: 'container-registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: containerImage
          name: name
          env: appSettings
          command: command
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

output serviceName string = containerApp.name
output principalId string = containerApp.identity.principalId
