#! /bin/bash

set -e

# Parse command line options for all required environment variables
while getopts c:g:l:i:s:t: option
do
case "${option}"
in
c) CLUSTER_NAME=${OPTARG};;
g) RESOURCE_GROUP=${OPTARG};;
l) LOCATION=${OPTARG};;
esac
done

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

az provider register -n "Microsoft.ExtendedLocation" || true
az provider register -n "Microsoft.Kubernetes" || true
az provider register -n "Microsoft.KubernetesConfiguration" || true
az provider register -n "Microsoft.IoTOperations" || true
az provider register -n "Microsoft.DeviceRegistry" || true
az provider register -n "Microsoft.SecretSyncController" || true

echo "Running command: az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_RAGRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --enable-hierarchical-namespace"
az storage account create --name $STORAGE_ACCOUNT_NAME --resource-group $RESOURCE_GROUP --location $LOCATION --sku Standard_RAGRS --kind StorageV2 --min-tls-version TLS1_2 --allow-blob-public-access false --enable-hierarchical-namespace

echo "Running command: az iot ops schema registry create --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP --registry-namespace $SCHEMA_REGISTRY_NAMESPACE --sa-resource-id $(az storage account show --name $STORAGE_ACCOUNT_NAME -o tsv --query id)"
az iot ops schema registry create --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP --registry-namespace $SCHEMA_REGISTRY_NAMESPACE --sa-resource-id $(az storage account show --name $STORAGE_ACCOUNT_NAME -o tsv --query id)

# Configure the Key Vault Extension on the Arc enabled cluster, cert and configmap
SR_RESOURCE_ID=$(az iot ops schema registry show --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP -o tsv --query id)

az iot ops init --cluster $CLUSTER_NAME -g $RESOURCE_GROUP

# Wait until all the azure arc containerstorage pods are running before creating the instance
echo "Waiting for pods in the azure-arc-containerstorage namespace to be ready..."
if ! kubectl wait --for=condition=Ready --timeout=300s pods -n azure-arc-containerstorage --all; then
    echo "Error: Some pods in the azure-arc-containerstorage namespace are not ready."
    exit 1
fi

az iot ops create --cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --name ${CLUSTER_NAME}-instance  --sr-resource-id $(az iot ops schema registry show --name $SCHEMA_REGISTRY --resource-group $RESOURCE_GROUP -o tsv --query id) --broker-frontend-replicas 1 --broker-frontend-workers 1  --broker-backend-part 1  --broker-backend-workers 1 --broker-backend-rf 2 --broker-mem-profile Low

echo "Creating MQTT client..."
kubectl create serviceaccount mqtt-client -n azure-iot-operations
kubectl apply -f ./deploy/client.yaml

echo "Finished deploying AIO Core components"
