param location string = 'eastus2'
param environment string = 'dev'
param appName string = 'azure-microservices'
param frontendRepoUrl string = 'https://github.com/kaweesha-nethmina/azure-microservices-lab'
param frontendBranch string = 'main'
param frontendAppLocation string = 'frontend'
param frontendOutputLocation string = ''
param frontendBuildCommand string = ''

var resourceGroupName = '${appName}-${environment}-rg'
var containerRegistryName = '${replace(appName, '-', '')}${environment}acr'
var containerEnvName = '${appName}-${environment}-env'
var gatewayAppName = '${appName}-${environment}-gateway'
var apiAppName = '${appName}-${environment}-api'
var frontendAppName = '${appName}-${environment}-frontend'
var acrLoginServer = containerRegistry.properties.loginServer

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

resource containerEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerEnvName
  location: location
}

resource gatewayContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: gatewayAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnvironment.id
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          name: 'gateway'
          image: '${acrLoginServer}/gateway:v1'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
          env: [
            {
              name: 'PORT'
              value: '3000'
            }
            {
              name: 'API_URL'
              value: 'http://${apiAppName}:5000'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

resource apiContainerApp 'Microsoft.App/containerApps@2022-03-01' = {
  name: apiAppName
  location: location
  properties: {
    managedEnvironmentId: containerEnvironment.id
    configuration: {
      ingress: {
        external: false
        targetPort: 5000
      }
    }
    template: {
      containers: [
        {
          name: 'api'
          image: '${acrLoginServer}/api:v1'
          resources: {
            cpu: 0.5
            memory: '1Gi'
          }
          env: [
            {
              name: 'PORT'
              value: '5000'
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
}

resource staticWebApp 'Microsoft.Web/staticSites@2021-03-01' = {
  name: frontendAppName
  location: location
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    repositoryUrl: frontendRepoUrl
    branch: frontendBranch
    buildProperties: {
      appLocation: frontendAppLocation
      outputLocation: frontendOutputLocation
      appBuildCommand: frontendBuildCommand
    }
  }
}

output containerRegistryLoginServer string = containerRegistry.properties.loginServer
output gatewayUrl string = 'https://${gatewayContainerApp.properties.configuration.ingress.fqdn}'
output staticWebAppUrl string = staticWebApp.properties.defaultHostname
