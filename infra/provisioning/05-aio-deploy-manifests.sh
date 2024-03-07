#! /bin/bash

set -e

if [ -z "$CLUSTER_NAME" ]; then
    echo "Error: CLUSTER_NAME is not set. This is needed for the name of the data processor instance."
    exit 1
fi

# Set TIMEOUT for script to the first argument of the script, or 1200 (20 minutes) if it's not set.
# This timeout is for waiting for the resources mq and data processor to be ready.
TIMEOUT=${1:-1200}

kubectl config set-context --current --namespace=azure-iot-operations

# Deploy MQ Broker, Listener and Diagnostics
kubectl apply -f ./deploy/cert-issuer.yaml
kubectl apply -f ./deploy/mq-broker.yaml

# Check for deployment of MQ Broker
kubectl get broker --namespace azure-iot-operations

# Check for running status of broker named 'mq-instance-broker'
echo "Checking for running status of broker named 'mq-instance-broker'"

kubectl wait --for=jsonpath='{.status.status}'="Running" broker/mq-instance-broker --timeout=${TIMEOUT}s

# Check for provsioning status of data processor instance
echo "Checking for provisioning status of data processor instance named '$CLUSTER_NAME-processor'"

kubectl wait --for=jsonpath='{.status.provisioningStatus.status}'="Succeeded" instance/$CLUSTER_NAME-processor --timeout=${TIMEOUT}s

echo "Finished deploying AIO"
