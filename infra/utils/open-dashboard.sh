#!/bin/bash

# Usage: ./open-dashboard.sh
# This script opens the Grafana dashboard in the default browser. It assumes that the OS Type is linux.

set -e

# Check if Az CLI is installed
if ! [ -x "$(command -v az)" ]; then
  echo 'Error: Az CLI is not installed.' >&2
  exit 1
fi

# Check if kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
  echo 'Error: kubectl is not installed.' >&2
  exit 1
fi

# Check if xdg-open is installed, if not, install it
if ! [ -x "$(command -v xdg-open)" ]; then
  echo 'xdg-open is not installed. Installing it..'
  sudo apt-get update
  sudo apt-get install xdg-utils -y
fi

RESOURCE_GROUP=$(kubectl get configmap azure-clusterconfig -o jsonpath='{.data.AZURE_RESOURCE_GROUP}' -n azure-arc) 
echo "Resource Group: $RESOURCE_GROUP"

# Verify that Resource Group is set
if [ -z "$RESOURCE_GROUP" ]; then
  echo "Resource Group is not set"
  exit 1
fi

AZURE_GRAFANA=$(az resource list --query "[?type=='Microsoft.Dashboard/grafana'].name" -o tsv -g $RESOURCE_GROUP)
echo "Azure Grafana: $AZURE_GRAFANA"

# Verify that Azure Grafana is set
if [ -z "$AZURE_GRAFANA" ]; then
  echo "Azure Grafana is not set"
  exit 1
fi

ENDPOINT=$(az grafana show -n $AZURE_GRAFANA -g $RESOURCE_GROUP --query  properties.endpoint -o tsv)

# Verify that the endpoint is set
if [ -z "$ENDPOINT" ]; then
  echo "Endpoint is not set"
  exit 1
fi

DASHBOARD_TITLE="Total Count and Machine Status"
DASHBOARD_URL_PATH=$(az grafana dashboard list -n $AZURE_GRAFANA -g $RESOURCE_GROUP --query  "[?title == '${DASHBOARD_TITLE}'].url" -o tsv)
echo "Opening dashboard link: $ENDPOINT$DASHBOARD_URL_PATH"

# Verify that the dashboard URL path is set
if [ -z "$DASHBOARD_URL_PATH" ]; then
  echo "Dashboard URL path is not set"
  exit 1
fi

# Open the dashboard in the default browser
xdg-open $ENDPOINT$DASHBOARD_URL_PATH
