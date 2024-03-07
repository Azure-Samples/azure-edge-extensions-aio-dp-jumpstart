#!/bin/bash

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if the user is logged in
if ! az account show &> /dev/null; then
    echo "Please log in to your Azure account using 'az login' before running this script."
    exit 1
fi

# Azure AD Service Principal creation

# Parameters
appName="$1"

# Get the subscription ID from the currently logged-in account
subscriptionId=$(az account show --query id --output tsv)

# Create a service principal with the owner role
echo "Creating Service Principal ..."
spAuthInfo=$(az ad sp create-for-rbac --name $appName --role owner --scopes /subscriptions/$subscriptionId --json-auth)

# Display the results
echo $spAuthInfo | jq  '{clientId, clientSecret, subscriptionId, tenantId}' > ~/.azure/servicePrincipal.json