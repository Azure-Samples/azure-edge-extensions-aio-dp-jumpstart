#! /bin/bash

set -e

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

if [ -z "$ARC_CUSTOMLOCATION_OID" ]; then
    echo "ARC_CUSTOMLOCATION_OID is not set. Setting it to the value of LOCATION $LOCATION."
    export ARC_CUSTOMLOCATION_OID="$LOCATION"
fi

az provider register -n "Microsoft.ExtendedLocation"
az provider register -n "Microsoft.Kubernetes"
az provider register -n "Microsoft.KubernetesConfiguration"
az provider register -n "Microsoft.IoTOperations"
az provider register -n "Microsoft.DeviceRegistry"
az provider register -n "Microsoft.SecretSyncController"

az group create --name $RESOURCE_GROUP --location $LOCATION

kubectl get nodes

# try connecting to Arc, if it fails, continue with debug code
set +e

az connectedk8s connect --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --location $LOCATION

status=$?

set -e

if [ $status -ne 0 ]; then
  echo "Failed to connect to Arc, continuing with debug code"
  kubectl get all -n azure-arc
  # loop and print through all logs for pre-boarding checks for debugging
  for entry in "/home/codespace/.azure/pre_onboarding_check_logs"/*
  do
    if [ -d "$entry" ]; then
        for child in "$entry"/*
        do
            echo "-------------------------"
            echo "$child"
            cat "$child"
        done
    else
        echo "-------------------------"
        echo "$entry"
        cat "$entry"
    fi
  done
  echo "Failed to connect to Arc"
  exit 1

fi

SERVICE_ACCOUNT_ISSUER=$(az connectedk8s show --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME --query oidcIssuerProfile.issuerUrl --output tsv)

# Add the service account issuer to the kubeconfig
echo "Adding service account issuer to kubeconfig"
cat <<EOF >> ~/.kube/config
kube-apiserver-arg:
  - service-account-issuer=$SERVICE_ACCOUNT_ISSUER
  - service-account-max-token-expiration=24h
EOF

kubectl get ns
kubectl get all -n azure-arc

echo "Enabling custom features in cluster"

az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid $ARC_CUSTOMLOCATION_OID --features cluster-connect custom-locations
echo "Restarting k3s to apply changes"
sudo systemctl restart k3s

echo "Arc connected to cluster $CLUSTER_NAME"