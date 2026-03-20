# Quick Start Guide

## Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Node.js 18+](https://nodejs.org/) (optional, for local development)
- [Git](https://git-scm.com/)

## Option 1: Local Development (Recommended for Testing)

### Step 1: Start Services with Docker Compose

```bash
# Navigate to project directory
cd azure-microservices-lab

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Services are now available:
# Frontend:  http://localhost
# Gateway:   http://localhost:3000
# API:       http://localhost:5000
```

### Step 2: Test the Application

**Option A: Using Browser**
1. Open http://localhost
2. Click "🔄 Check Services" to verify all services are running
3. Click "📋 Load Users" to fetch data
4. Click "➕ Add User" to create a new user

**Option B: Using curl**
```bash
# Check gateway health
curl http://localhost:3000/health

# Get all users
curl http://localhost:5000/users

# Create a user
curl -X POST http://localhost:5000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice","email":"alice@example.com"}'
```

### Step 3: Stop Services

```bash
docker-compose down

# To also remove volumes
docker-compose down -v
```

---

## Option 2: Azure Deployment

### Prerequisites
```bash
# Login to Azure
az login

# Check your subscription
az account list --output table
```

### Step 1: Set Environment Variables

```bash
source .env.production
echo $AZURE_RESOURCE_GROUP
echo $AZURE_LOCATION
```

### Step 2: Create Azure Resources

```bash
# Create resource group
az group create \
  --name $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION

# Create container registry
az acr create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --sku Basic

# Login to ACR
az acr login --name $CONTAINER_REGISTRY_NAME
```

### Step 3: Build and Push Container Images

```bash
# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query loginServer -o tsv)

echo $ACR_LOGIN_SERVER

# Build Gateway image
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image gateway:latest \
  ./gateway

# Build API image
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image api:latest \
  ./api

# Verify images
az acr repository list --name $CONTAINER_REGISTRY_NAME
```

### Step 4: Deploy to Azure Container Apps

```bash
# Create container environment
az containerapp env create \
  --name azure-microservices-env \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION

# Get ACR credentials
REGISTRY_USERNAME=$(az acr credential show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query username -o tsv)

REGISTRY_PASSWORD=$(az acr credential show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query passwords[0].value -o tsv)

# Deploy API container app
az containerapp create \
  --name api-app \
  --resource-group $AZURE_RESOURCE_GROUP \
  --environment azure-microservices-env \
  --image $ACR_LOGIN_SERVER/api:latest \
  --target-port 5000 \
  --ingress internal \
  --cpu 0.5 \
  --memory 1.0Gi \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $REGISTRY_USERNAME \
  --registry-password $REGISTRY_PASSWORD \
  --environment-variables PORT=5000

# Deploy Gateway container app
az containerapp create \
  --name gateway-app \
  --resource-group $AZURE_RESOURCE_GROUP \
  --environment azure-microservices-env \
  --image $ACR_LOGIN_SERVER/gateway:latest \
  --target-port 3000 \
  --ingress external \
  --cpu 0.5 \
  --memory 1.0Gi \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $REGISTRY_USERNAME \
  --registry-password $REGISTRY_PASSWORD \
  --environment-variables PORT=3000 API_URL=http://api-app:5000
```

### Step 5: Deploy Frontend

```bash
# Create static web app (connect to GitHub)
az staticwebapp create \
  --name frontend-app \
  --resource-group $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION \
  --source ./frontend
```

### Step 6: Get Service URLs

```bash
# Get Gateway public URL
GATEWAY_URL=$(az containerapp show \
  --name gateway-app \
  --resource-group $AZURE_RESOURCE_GROUP \
  --query properties.configuration.ingress.fqdn -o tsv)

echo "Gateway URL: https://$GATEWAY_URL"

# Test Gateway
curl https://$GATEWAY_URL/health
```

---

## Troubleshooting

### Docker Compose Issues

**Services won't start:**
```bash
# Check logs
docker-compose logs

# Rebuild images
docker-compose build --no-cache

# Start fresh
docker-compose down -v && docker-compose up -d
```

**Port already in use:**
```bash
# Find process using port 3000
lsof -i :3000
# Kill process
kill -9 <PID>
```

### Azure Issues

**Authentication failed:**
```bash
az login --use-device-code
```

**Image push failed:**
```bash
# Verify ACR login
az acr login --name $CONTAINER_REGISTRY_NAME

# Check image exists locally
docker images | grep gateway
```

**Container won't start:**
```bash
# View container logs
az containerapp logs show \
  --name gateway-app \
  --resource-group $AZURE_RESOURCE_GROUP
```

---

## Cleanup

### Local
```bash
docker-compose down -v
```

### Azure
```bash
# Delete entire resource group (⚠️ CAUTION)
az group delete \
  --name $AZURE_RESOURCE_GROUP \
  --yes --no-wait
```

---

## Next Steps

1. ✅ Running locally with Docker Compose
2. ✅ Deployed to Azure
3. ⭐ Add GitHub Actions CI/CD pipeline
4. ⭐ Add application monitoring
5. ⭐ Add database integration
6. ⭐ Setup SSL certificates
7. ⭐ Configure auto-scaling

For detailed deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
