#! /bin/bash

set -e

# Function to check if the required environment variables are set
check_env_var() {
    if [[ -z "${!1}" ]]; then
        echo "$1 is not set"
        exit 1
    fi
}

# Function to create a k8s extension
create_k8s_extension() {
    az k8s-extension create --name $1 --cluster-name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --cluster-type connectedClusters --extension-type $2 --configuration-settings azure-monitor-workspace-resource-id="$AZ_MONITOR_ID"
}

# Function to generate random values that can be used to make a name unique.
generate_random_hash() {
  timestamp=$(date +%s)
  hash=$(echo -n $timestamp | sha256sum | cut -c1-4)
  random=$RANDOM
  echo "${hash}-${random:0:4}"
}

echo "== Enabling observability =="

check_env_var "CLUSTER_NAME"
check_env_var "RESOURCE_GROUP"

az provider register --namespace Microsoft.AlertsManagement

az config set extension.use_dynamic_install=yes_without_prompt

# Create a monitor workspace
echo "Creating an Azure Monitor Logs Analytics Workspace ..."
az monitor account create -n "monitor-$CLUSTER_NAME" -g $RESOURCE_GROUP

export PROMETHEUS_ENDPOINT=$(az monitor account show -n "monitor-$CLUSTER_NAME" -g $RESOURCE_GROUP --query metrics.prometheusQueryEndpoint -o tsv)
export AZ_MONITOR_ID=$(az monitor account show -n "monitor-$CLUSTER_NAME" -g $RESOURCE_GROUP --query id -o tsv)

echo "Prometheus endpoint: $PROMETHEUS_ENDPOINT"

# Enable Prometheus metrics collection from your Arc-enabled Kubernetes cluster to the monitor prev created
echo "Enabling prometheus metrics collection ..."
create_k8s_extension "azuremonitor-metrics" "Microsoft.AzureMonitor.Containers.Metrics"

# Enable container insights (optional for dp purposes)
echo "Enabling container insights ..."
create_k8s_extension "azuremonitor-containers" "Microsoft.AzureMonitor.Containers"

# Custom metrics including data processing ones
echo "Enabling custom metrics ..."
kubectl apply -f ./deploy/ama-metrics-prometheus.yaml

echo "Creating Azure Managed Grafana ..."

# Dashboard name must contain between 2-23 characters
DASHBOARD_NAME="dsb-${CLUSTER_NAME:0:9}-$(generate_random_hash)"

echo "Creating Azure Managed Grafana dashboard: ${DASHBOARD_NAME}"
az grafana create --name $DASHBOARD_NAME --resource-group $RESOURCE_GROUP

echo "Creating prometheus data source for grafana ..."
az grafana data-source create -n $DASHBOARD_NAME --definition "{
  \"name\": \"prometheus-$CLUSTER_NAME\",  \
  \"type\": \"prometheus\",  \
  \"access\": \"proxy\",  \
  \"url\": \"$PROMETHEUS_ENDPOINT\",  \
  \"jsonData\": { \
    \"httpMethod\": \"POST\", \
    \"azureCredentials\": { \"authType\": \"msi\" } \
  } }"

# Import sample dashboard
SAMPLE_DASHBOARD_PATH="@../deployment/dashboards/zurich-total-count-and-machine-status.json"

az grafana dashboard import --definition $SAMPLE_DASHBOARD_PATH --name $DASHBOARD_NAME --resource-group $RESOURCE_GROUP
endpoint=$(az grafana show -n $DASHBOARD_NAME -g $RESOURCE_GROUP --query  properties.endpoint -o tsv)

DASHBOARD_TITLE="Total Count and Machine Status"
dashboard_url=$(az grafana dashboard list -n $DASHBOARD_NAME -g $RESOURCE_GROUP --query  "[?title == '${DASHBOARD_TITLE}'].url" -o tsv)

echo "{\"dashboard-url\": \"${endpoint}${dashboard_url}\"}" > ~/.azure/grafana.json