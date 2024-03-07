#! /bin/bash

set -e

# check if the required environment variables are set
if [ -z "${CLUSTER_NAME}" ]; then
    echo "CLUSTER_NAME is not set"
    exit 1
fi
if [ -z "$RESOURCE_GROUP" ]; then
    echo "RESOURCE_GROUP is not set"
    exit 1
fi
if [ -z "$LOCATION" ]; then
    echo "LOCATION is not set"
    exit 1
fi
if [ -z "$AKV_SP_CLIENT_ID" ]; then
    echo "AKV_SP_CLIENT_ID is not set"
    exit 1
fi
if [ -z "$AKV_SP_CLIENT_SECRET" ]; then
    echo "AKV_SP_CLIENT_SECRET is not set"
    exit 1
fi

if [ -z "$AKV_SP_OBJECT_ID" ]; then
    AKV_SP_OBJECT_ID=$(az ad sp show --id $AKV_SP_CLIENT_ID --query id -o tsv)
fi

# Create Key Vault
random=$RANDOM
RG_FOR_AKV="${RESOURCE_GROUP//-/}" # Remove hyphens from resource group name
AKV_NAME="kv${RG_FOR_AKV:0:18}${random:0:4}" # AKV name must be between 3 and 24 characters

echo "Creating keyvault $AKV_NAME"
az keyvault create -n $AKV_NAME -g $RESOURCE_GROUP --enable-rbac-authorization false
keyVaultResourceId=$(az keyvault show -n $AKV_NAME -g $RESOURCE_GROUP -o tsv --query id)

# Set AKV policy
echo "Setting AKV policy"
az keyvault set-policy -n $AKV_NAME -g $RESOURCE_GROUP --object-id $AKV_SP_OBJECT_ID --secret-permissions get set list --key-permissions get list

# Configure the Key Vault Extension on the Arc enabled cluster, cert and configmap
az iot ops init --cluster $CLUSTER_NAME -g $RESOURCE_GROUP --kv-id $keyVaultResourceId \
    --sp-app-id $AKV_SP_CLIENT_ID \
    --sp-object-id $AKV_SP_OBJECT_ID \
    --sp-secret "$AKV_SP_CLIENT_SECRET" \
    --no-deploy

echo "Check if AKV extension is installed"
kubectl get pods -n kube-system

echo "Finished deploying AIO Core components"