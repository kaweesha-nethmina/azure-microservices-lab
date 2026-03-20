#!/bin/bash

# Setup Azure Authentication for GitHub Actions Pipeline

# Variables
SUBSCRIPTION_ID="2518b0fb-d732-4a95-bbe3-07b9d2ce2731"
RESOURCE_GROUP="ctse"
MI_NAME="pipeline-mi"
MI_RG="pipeline-identities"
LOCATION="southeastasia"
GITHUB_REPO="kaweesha-nethmina/azure-microservices-lab"

# Create Resource Group for MI
echo "Creating resource group for managed identity..."
az group create --name $MI_RG --location $LOCATION --subscription $SUBSCRIPTION_ID

# Create Managed Identity
echo "Creating User-Assigned Managed Identity..."
az identity create --name $MI_NAME --resource-group $MI_RG --location $LOCATION --subscription $SUBSCRIPTION_ID

# Get MI details
MI_CLIENT_ID=$(az identity show --name $MI_NAME --resource-group $MI_RG --query clientId -o tsv)
MI_PRINCIPAL_ID=$(az identity show --name $MI_NAME --resource-group $MI_RG --query principalId -o tsv)

# Assign roles
echo "Assigning roles..."
az role assignment create --assignee $MI_PRINCIPAL_ID --role Contributor --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP

# Add federated credentials
echo "Setting up federated credentials..."
az identity federated-credential create --name github-federated --identity-name $MI_NAME --resource-group $MI_RG --issuer https://token.actions.githubusercontent.com --subject repo:$GITHUB_REPO:environment:dev --audiences api://AzureADTokenExchange

# Output for GitHub secrets
echo "GitHub Secrets to set:"
echo "AZURE_CLIENT_ID: $MI_CLIENT_ID"
echo "AZURE_TENANT_ID: $(az account show --query tenantId -o tsv)"
echo "AZURE_SUBSCRIPTION_ID: $SUBSCRIPTION_ID"

# Create GitHub environment (using GitHub CLI if available)
# gh api repos/$GITHUB_REPO/environments/dev -X PUT -f wait_timer=0 -f reviewers='[]'