#!/bin/bash

# Check if parameters are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <cluster-name> <resource-group>"
    exit 1
fi

# Define the list of expected extensions
expected_extensions=("microsoft.iotoperations" "microsoft.iotoperations.platform" "microsoft.azure.secretstore" "microsoft.arc.containerstorage")

# Get the list of installed extensions
installed_extensions=$(az k8s-extension list --cluster-type connectedClusters --cluster-name $1 --resource-group $2 --query "[].extensionType" -o tsv)

# Check each expected extension
for extension in "${expected_extensions[@]}"; do
  if echo "$installed_extensions" | grep -q "$extension"; then
    echo "$extension is installed"
  else
    echo "$extension is NOT installed"
    exit 1
  fi
done