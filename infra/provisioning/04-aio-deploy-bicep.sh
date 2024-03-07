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

if [ -z "$AIO_DEPLOYMENT_NAME" ]; then
    random=$RANDOM
    deploymentName="aio-deployment-$random"
else
    deploymentName=$AIO_DEPLOYMENT_NAME
fi

# Change here for testing
templateName="main.bicep"

echo "Deployment Name: $deploymentName"

echo "Check if AKV extension is installed"
kubectl get pods -n kube-system

# Deploy bicep for AIO orchestrator, MQ, DP, DeviceRegistry(?) - focus on Arc Extensions in Bicep
az deployment group create \
    --resource-group $RESOURCE_GROUP \
    --name $deploymentName \
    --template-file "./bicep/$templateName" \
    --parameters clusterName=$CLUSTER_NAME \
    --parameters location=$LOCATION \
    --parameters resourceGroup=$RESOURCE_GROUP \
    --verbose --no-prompt

echo "Finished deploying AIO components"