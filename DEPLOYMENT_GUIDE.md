# Azure Microservices Lab - Deployment Guide

## Step-by-Step Deployment Instructions

### Phase 1: Local Development & Testing

#### 1.1 Clone and Setup

```bash
cd azure-microservices-lab
```

#### 1.2 Local Development with Docker Compose

```bash
# Start all services
docker-compose up -d

# Verify services
docker ps

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

#### 1.3 Test Services Locally

```bash
# Test Gateway
curl http://localhost:3000

# Test API - Get all users
curl http://localhost:5000/users

# Test API - Create user
curl -X POST http://localhost:5000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# Test Frontend
open http://localhost
```

---

### Phase 2: Azure Setup

#### 2.1 Prerequisites

Install required tools:
```bash
# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify installation
az --version
```

#### 2.2 Azure Login

```bash
az login

# Verify subscription
az account list --output table
```

#### 2.3 Create Service Principal for CI/CD

```bash
# Get your subscription ID
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create service principal
az ad sp create-for-rbac \
  --name "github-actions-microservices" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --json-auth > credentials.json

# View credentials (save for GitHub Secrets)
cat credentials.json
```

---

### Phase 3: Azure Resources

#### 3.1 Create Resource Group

```bash
source .env.production

az group create \
  --name $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION

# Verify
az group show --name $AZURE_RESOURCE_GROUP
```

#### 3.2 Create Container Registry

```bash
az acr create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --sku Basic \
  --admin-enabled true

# Get login credentials
az acr credential show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME
```

#### 3.3 Login to Container Registry

```bash
# Get login server
ACR_URL=$(az acr show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query loginServer -o tsv)

echo $ACR_URL

# Login
az acr login --name $CONTAINER_REGISTRY_NAME
```

---

### Phase 4: Build and Push Container Images

#### 4.1 Build Gateway Image

```bash
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image gateway:latest \
  --image gateway:v1.0 \
  ./gateway
```

#### 4.2 Build API Image

```bash
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image api:latest \
  --image api:v1.0 \
  ./api
```

#### 4.3 Verify Images in Registry

```bash
az acr repository list --name $CONTAINER_REGISTRY_NAME

az acr repository show-tags \
  --name $CONTAINER_REGISTRY_NAME \
  --repository gateway
```

---

### Phase 5: Deploy Infrastructure

#### 5.1 Deploy Bicep Template

```bash
az deployment group create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --template-file ./infra/main.bicep \
  --parameters ./infra/parameters.json

# View deployment outputs
az deployment group show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name main \
  --query properties.outputs
```

#### 5.2 Verify Container Apps Environment

```bash
az containerapp env list \
  --resource-group $AZURE_RESOURCE_GROUP
```

---

### Phase 6: Deploy Containers to Azure Container Apps

#### 6.1 Create Container Apps Environment (if not created by Bicep)

```bash
az containerapp env create \
  --name azure-microservices-prod-env \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION
```

#### 6.2 Deploy Gateway Container App

```bash
az containerapp create \
  --name $GATEWAY_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --environment azure-microservices-prod-env \
  --image $ACR_URL/gateway:latest \
  --target-port 3000 \
  --ingress external \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --registry-login-server $ACR_URL \
  --registry-username $(az acr credential show --name $CONTAINER_REGISTRY_NAME --query username -o tsv) \
  --registry-password $(az acr credential show --name $CONTAINER_REGISTRY_NAME --query passwords[0].value -o tsv) \
  --environment-variables PORT=3000 API_URL=http://$API_APP_NAME:5000
```

#### 6.3 Deploy API Container App

```bash
az containerapp create \
  --name $API_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --environment azure-microservices-prod-env \
  --image $ACR_URL/api:latest \
  --target-port 5000 \
  --ingress internal \
  --cpu 0.5 \
  --memory 1.0Gi \
  --min-replicas 1 \
  --max-replicas 3 \
  --registry-login-server $ACR_URL \
  --registry-username $(az acr credential show --name $CONTAINER_REGISTRY_NAME --query username -o tsv) \
  --registry-password $(az acr credential show --name $CONTAINER_REGISTRY_NAME --query passwords[0].value -o tsv) \
  --environment-variables PORT=5000
```

#### 6.4 Get Service URLs

```bash
# Gateway URL
GATEWAY_URL=$(az containerapp show \
  --name $GATEWAY_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "Gateway URL: https://$GATEWAY_URL"

# Test Gateway
curl https://$GATEWAY_URL
```

---

### Phase 7: Deploy Frontend

#### 7.1 Create Static Web App

```bash
az staticwebapp create \
  --name $FRONTEND_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION \
  --source "frontend" \
  --branch main \
  --token $GITHUB_TOKEN
```

#### 7.2 Configure Frontend for Gateway

Update `frontend/index.html` to use the deployed Gateway URL:

```html
<script>
  const GATEWAY_URL = "https://<your-gateway-url>";
  
  function checkBackend() {
    fetch(`${GATEWAY_URL}/`)
      .then(res => res.json())
      .then(data => {
        document.getElementById("result").innerText = "Backend Status: " + data.status;
      })
      .catch(() => {
        document.getElementById("result").innerText = "Backend not reachable ❌";
      });
  }
</script>
```

---

### Phase 8: Setup CI/CD Pipeline (GitHub Actions)

#### 8.1 Add GitHub Secrets

1. Go to GitHub repository settings
2. Navigate to Secrets and variables → Actions
3. Add the following secrets:

```
REGISTRY_LOGIN_SERVER = <your-acr-login-server>
REGISTRY_USERNAME = <your-acr-username>
REGISTRY_PASSWORD = <your-acr-password>
AZURE_CREDENTIALS = <contents of credentials.json>
```

#### 8.2 Trigger Deployment

```bash
git add .
git commit -m "Deploy microservices to Azure"
git push origin main
```

#### 8.3 Monitor Deployment

1. Go to Actions tab in GitHub
2. Select the running workflow
3. View logs in real-time

---

### Phase 9: Testing & Validation

#### 9.1 Test Gateway

```bash
curl "https://$GATEWAY_URL/"
```

#### 9.2 Test API through Gateway

```bash
curl "https://$GATEWAY_URL/users"
```

#### 9.3 Test Frontend

Open `https://<your-static-web-app-url>` in browser

---

### Phase 10: Monitoring & Management

#### 10.1 View Container App Logs

```bash
az containerapp logs show \
  --name $GATEWAY_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP

az containerapp logs show \
  --name $API_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP
```

#### 10.2 Scale Container Apps

```bash
# Update replica range
az containerapp update \
  --name $GATEWAY_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --min-replicas 2 \
  --max-replicas 5
```

#### 10.3 Update Deployment

```bash
# Update to new image
az containerapp update \
  --name $GATEWAY_APP_NAME \
  --resource-group $AZURE_RESOURCE_GROUP \
  --image $ACR_URL/gateway:latest
```

---

## Cleanup

### Delete All Azure Resources

```bash
# This will delete the entire resource group and all resources
az group delete \
  --name $AZURE_RESOURCE_GROUP \
  --yes \
  --no-wait

# Verify deletion
az group list --output table
```

---

## Common Issues & Solutions

### Issue: Container fails to pull image
**Solution:** Verify ACR credentials and image name
```bash
az acr repository list --name $CONTAINER_REGISTRY_NAME
```

### Issue: Gateway cannot connect to API
**Solution:** Check container app networking
```bash
az containerapp show --name $API_APP_NAME --resource-group $AZURE_RESOURCE_GROUP
```

### Issue: Frontend cannot reach Gateway
**Solution:** Update frontend URL and CORS settings in gateway

---

## Next Steps

1. ✅ Local testing with Docker Compose
2. ✅ Azure resource creation
3. ✅ Container image builds
4. ✅ Container Apps deployment
5. ✅ Frontend deployment
6. ✅ CI/CD pipeline setup
7. ⭐ Add database (Azure Cosmos DB or SQL)
8. ⭐ Add monitoring (Application Insights)
9. ⭐ Add caching (Azure Cache for Redis)
10. ⭐ Implement auto-scaling policies
