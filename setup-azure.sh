#!/bin/bash

# Azure Microservices Lab - Setup Script
# This script sets up the entire Azure microservices environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}======================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

# Load environment
print_header "Loading Environment Variables"
if [ -f .env.production ]; then
    source .env.production
    print_success "Loaded .env.production"
else
    print_error ".env.production not found"
    exit 1
fi

# Check prerequisites
print_header "Checking Prerequisites"

if command -v az &> /dev/null; then
    print_success "Azure CLI installed"
else
    print_error "Azure CLI not installed"
    exit 1
fi

if command -v docker &> /dev/null; then
    print_success "Docker installed"
else
    print_error "Docker not installed"
    exit 1
fi

# Azure Login
print_header "Azure Login"
az account show > /dev/null 2>&1 || az login
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
print_success "Logged in to subscription: $SUBSCRIPTION_ID"

# Create Resource Group
print_header "Creating Resource Group"
az group create \
    --name $AZURE_RESOURCE_GROUP \
    --location $AZURE_LOCATION \
    --output none
print_success "Resource group created: $AZURE_RESOURCE_GROUP"

# Create Container Registry
print_header "Creating Container Registry"
az acr create \
    --resource-group $AZURE_RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME \
    --sku Basic \
    --admin-enabled true \
    --output none
print_success "Container registry created: $CONTAINER_REGISTRY_NAME"

# Get ACR Details
ACR_LOGIN_SERVER=$(az acr show \
    --resource-group $AZURE_RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME \
    --query loginServer -o tsv)

REGISTRY_USERNAME=$(az acr credential show \
    --resource-group $AZURE_RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME \
    --query username -o tsv)

REGISTRY_PASSWORD=$(az acr credential show \
    --resource-group $AZURE_RESOURCE_GROUP \
    --name $CONTAINER_REGISTRY_NAME \
    --query passwords[0].value -o tsv)

print_info "ACR Login Server: $ACR_LOGIN_SERVER"

# Login to ACR
print_info "Logging into Container Registry..."
az acr login --name $CONTAINER_REGISTRY_NAME
print_success "Logged into ACR"

# Build Images Locally and Push to ACR
print_header "Building Container Images"

print_info "Building Gateway image locally..."
docker build -t $ACR_LOGIN_SERVER/gateway:latest ./gateway
docker push $ACR_LOGIN_SERVER/gateway:latest
print_success "Gateway image built and pushed"

print_info "Building API image locally..."
docker build -t $ACR_LOGIN_SERVER/api:latest ./api
docker push $ACR_LOGIN_SERVER/api:latest
print_success "API image built and pushed"

# Create Container Environment
print_header "Creating Container Apps Environment"
ENV_NAME="${CONTAINER_REGISTRY_NAME}-env"
az containerapp env create \
    --name "$ENV_NAME" \
    --resource-group $AZURE_RESOURCE_GROUP \
    --location $AZURE_LOCATION \
    --output none
print_success "Container environment created: $ENV_NAME"

# Deploy API
print_header "Deploying API Service"
az containerapp create \
    --name $API_APP_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --environment "$ENV_NAME" \
    --image "$ACR_LOGIN_SERVER/api:v2" \
    --target-port 5000 \
    --ingress internal \
    --cpu 0.5 \
    --memory 1.0Gi \
    --min-replicas 1 \
    --max-replicas 3 \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-username "$REGISTRY_USERNAME" \
    --registry-password "$REGISTRY_PASSWORD" \
    --env-vars PORT=5000 \
    --output none
print_success "API service deployed"

# Deploy Gateway
print_header "Deploying Gateway Service"
az containerapp create \
    --name $GATEWAY_APP_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --environment "$ENV_NAME" \
    --image "$ACR_LOGIN_SERVER/gateway:v2" \
    --target-port 3000 \
    --ingress external \
    --cpu 0.5 \
    --memory 1.0Gi \
    --min-replicas 1 \
    --max-replicas 3 \
    --registry-server "$ACR_LOGIN_SERVER" \
    --registry-username "$REGISTRY_USERNAME" \
    --registry-password "$REGISTRY_PASSWORD" \
    --env-vars PORT=3000 API_URL=http://$API_APP_NAME:5000 \
    --output none
print_success "Gateway service deployed"

# Get Gateway URL
GATEWAY_URL=$(az containerapp show \
    --name $GATEWAY_APP_NAME \
    --resource-group $AZURE_RESOURCE_GROUP \
    --query properties.configuration.ingress.fqdn -o tsv)

print_header "Deployment Summary"
print_success "All services deployed successfully!"
echo ""
echo -e "Gateway URL: ${GREEN}https://$GATEWAY_URL${NC}"
echo -e "API URL (internal): http://$API_APP_NAME:5000"
echo ""
print_info "Test the deployment:"
echo "  curl https://$GATEWAY_URL/health"
echo ""
print_info "View logs:"
echo "  az containerapp logs show --name $GATEWAY_APP_NAME --resource-group $AZURE_RESOURCE_GROUP"
echo ""
print_info "Cleanup (⚠️  WARNING - Deletes all resources):"
echo "  az group delete --name $AZURE_RESOURCE_GROUP --yes"
