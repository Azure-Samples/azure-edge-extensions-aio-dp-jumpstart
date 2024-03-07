#!/bin/bash

SKIP_RG=0

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    --skip-rg)
      SKIP_RG=1
      shift
      ;;
    *)
      echo "Error: Invalid argument"
      exit 1
      ;;
  esac
done

# Delete Azure resources only if --skip-rg is not provided
if [ $SKIP_RG -eq 0 ]; then
    if [ -z "$RESOURCE_GROUP" ]; then
        RESOURCE_GROUP=$(kubectl get configmap azure-clusterconfig -o jsonpath='{.data.AZURE_RESOURCE_GROUP}' -n azure-arc)
    fi

    az group delete --name $RESOURCE_GROUP --yes --no-wait
    echo "Azure resource group '$RESOURCE_GROUP' is being deleted"
fi

export K3D_FIX_MOUNTS=1

# Delete k3d registry if it exists
if k3d registry list | grep -q 'devregistry.localhost'; then
    k3d registry delete devregistry.localhost
    echo "K3D registry deleted"
fi

k3d cluster delete devcluster

# Create local registry for K3D and local development
k3d registry create devregistry.localhost  --port 5500

# Create k3d cluster with NFS support and forwarded ports
# See https://github.com/jlian/k3d-nfs
# Note devregistry.localhost needs to be passed into the cluster with the prefix `k3d-`
k3d cluster create devcluster --registry-use k3d-devregistry.localhost:5500 -i ghcr.io/jlian/k3d-nfs:v1.25.3-k3s1 \
-p '1883:1883@loadbalancer' \
-p '8883:8883@loadbalancer' \
-p '6001:6001@loadbalancer' \
-p '4000:80@loadbalancer'

echo "K3D registry and cluster created again, you can now run through Readme for installation"