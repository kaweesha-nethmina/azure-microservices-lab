# Azure Microservices Lab

A complete microservices application deployed on Azure with containerization and CI/CD pipeline.

## Project Structure

```
.
├── gateway/              # API Gateway service (Node.js/Express)
├── api/                  # Backend API service (Node.js/Express)
├── frontend/             # Frontend application (HTML)
├── infra/                # Azure Infrastructure as Code (Bicep)
├── .github/workflows/    # CI/CD pipelines (GitHub Actions)
├── docker-compose.yml    # Local development orchestration
└── README.md            # This file
```

## Services

### Gateway Service (Port 3000)
- Entry point for all client requests
- Routes requests to appropriate microservices
- Handles CORS

**Files:**
- `gateway/package.json` - Dependencies
- `gateway/server.js` - Express server implementation
- `gateway/Dockerfile` - Container configuration

### API Service (Port 5000)
- Provides REST API for user management
- Endpoints: `/users`, `/users/:id`
- CRUD operations on users

**Files:**
- `api/package.json` - Dependencies
- `api/server.js` - Express server implementation
- `api/Dockerfile` - Container configuration

### Frontend
- Static web application
- Communicates with gateway
- Hosted on Azure Static Web Apps

**Files:**
- `frontend/index.html` - Frontend application

## Local Development

### Prerequisites
- Docker & Docker Compose
- Node.js 18+ (for local development without Docker)
- Azure CLI (for Azure deployments)

### Running Locally with Docker Compose

```bash
# Navigate to project root
cd azure-microservices-lab

# Start all services
docker-compose up -d

# Services will be available at:
# - Frontend: http://localhost:80
# - Gateway: http://localhost:3000
# - API: http://localhost:5000
```

### Running Locally without Docker

**Terminal 1 - API Service:**
```bash
cd api
npm install
npm start
```

**Terminal 2 - Gateway Service:**
```bash
cd gateway
npm install
npm start
```

**Terminal 3 - Frontend:**
Serve `frontend/index.html` using any HTTP server:
```bash
cd frontend
python -m http.server 8000
# or
npx http-server
```

## Azure Deployment

### Prerequisites
- Azure CLI installed and logged in
- An Azure subscription
- Docker installed

### Setup Steps

1. **Set up environment variables:**
```bash
source .env.production
```

2. **Create Azure resources:**
```bash
az group create \
  --name $AZURE_RESOURCE_GROUP \
  --location $AZURE_LOCATION
```

3. **Deploy infrastructure using Bicep:**
```bash
az deployment group create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --template-file ./infra/main.bicep \
  --parameters ./infra/parameters.json
```

4. **Create Azure Container Registry:**
```bash
az acr create \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --sku Basic
```

5. **Build and push container images:**
```bash
# Get ACR login server
ACR_URL=$(az acr show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name $CONTAINER_REGISTRY_NAME \
  --query loginServer -o tsv)

# Log in to ACR
az acr login --name $CONTAINER_REGISTRY_NAME

# Build and push Gateway
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image gateway:latest \
  ./gateway

# Build and push API
az acr build \
  --registry $CONTAINER_REGISTRY_NAME \
  --image api:latest \
  ./api
```

### Using GitHub Actions (Recommended)

1. **Add GitHub Secrets** in your repository:
   - `REGISTRY_LOGIN_SERVER` - Your ACR login server
   - `REGISTRY_USERNAME` - Your ACR username
   - `REGISTRY_PASSWORD` - Your ACR password (or access key)
   - `AZURE_CREDENTIALS` - Azure service principal credentials

2. **Create service principal for Azure login:**
```bash
az ad sp create-for-rbac \
  --name "github-actions" \
  --role Contributor \
  --scopes /subscriptions/{subscription-id} \
  --json-auth
```

3. **Push to main branch** to trigger deployment:
```bash
git add .
git commit -m "Deploy to Azure"
git push origin main
```

## API Endpoints

### Gateway
- `GET /` - Health check

### API Service
- `GET /health` - Health check
- `GET /users` - Get all users
- `GET /users/:id` - Get user by ID
- `POST /users` - Create new user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

### Example Requests

```bash
# Get all users
curl http://localhost:5000/users

# Create user
curl -X POST http://localhost:5000/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Update user
curl -X PUT http://localhost:5000/users/{id} \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane Doe"}'

# Delete user
curl -X DELETE http://localhost:5000/users/{id}
```

## Environment Variables

### Local Development (.env.local)
```
ENVIRONMENT=local
GATEWAY_PORT=3000
API_PORT=5000
API_URL=http://localhost:5000
GATEWAY_URL=http://localhost:3000
```

### Production (.env.production)
```
ENVIRONMENT=production
AZURE_RESOURCE_GROUP=azure-microservices-rg
AZURE_LOCATION=southeastasia
CONTAINER_REGISTRY_NAME=microsvcregistry
```

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                    Azure                            │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────────────────────────────────┐  │
│  │     Static Web App (Frontend)                │  │
│  │     - index.html                             │  │
│  └──────────────────────────────────────────────┘  │
│                       │                            │
│                       ▼                            │
│  ┌──────────────────────────────────────────────┐  │
│  │     Container Apps (Gateway)                 │  │
│  │     - Express server on port 3000            │  │
│  │     - Routes to API service                  │  │
│  └──────────────────────────────────────────────┘  │
│                       │                            │
│                       ▼                            │
│  ┌──────────────────────────────────────────────┐  │
│  │     Container Apps (API)                     │  │
│  │     - User service on port 5000              │  │
│  │     - CRUD operations                        │  │
│  └──────────────────────────────────────────────┘  │
│                                                     │
└─────────────────────────────────────────────────────┘
```

## Troubleshooting

### Container not starting
```bash
docker logs <container-id>
```

### Permission denied when building images
```bash
sudo usermod -aG docker $USER
```

### Azure deployment fails
```bash
az deployment group show \
  --resource-group $AZURE_RESOURCE_GROUP \
  --name main
```

## Cleanup

### Local Docker
```bash
docker-compose down
```

### Azure Resources
```bash
az group delete \
  --name $AZURE_RESOURCE_GROUP \
  --yes --no-wait
```

## References

- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Bicep Documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## License

MIT
