#!/bin/bash

set -e

TIMEOUT=30

# Parse command-line arguments
while (( "$#" )); do
  case "$1" in
    -t|--timeout)
      TIMEOUT="$2"
      shift 2
      ;;
     *)
      echo "Error: Invalid argument"
      exit 1
      ;;
  esac
done

verify_prereq_tools_installed() {
    # Check if kubectl is installed
  if ! command -v kubectl &> /dev/null
  then
      echo "Kubectl could not be found. Please install it and try again."
      exit
  fi

  # Check if Docker is installed
  if ! command -v docker &> /dev/null
  then
      echo "Docker could not be found. Please install it and try again."
      exit
  fi
}

navigate_to_deployments_folder() {
  SCRIPT_DIR=$(dirname "$0")
  cd $SCRIPT_DIR
}

# Function to wait for an object provisioning status to become "Succeeded"
wait_for_readiness() {
  local object_name=$1
  local timeout=$2

  kubectl wait --for=jsonpath='{.status.provisioningStatus.status}'="Succeeded" ${object_name} --timeout=${timeout}s --namespace azure-iot-operations
}

build_and_push_http_server() {
  # Navigate to the http-server-ref folder
  pushd http-server-ref

  # Build the Docker image of the server that reads the reference data
  docker build -t ref-http-server .

  # Push the image to the local k3d registry
  # This command assumes that your local k3d registry is running at localhost:5000
  docker tag ref-http-server localhost:5500/ref-http-server
  docker push localhost:5500/ref-http-server

  sleep 5
  popd
  echo "Docker image has been built and pushed to the local k3d registry."
}

apply_datasets() {
  # Apply the datasets
  kubectl apply -k ./dp-pipelines/dataset
  kubectl get datasets -n azure-iot-operations
  # #(optional) If you want to update the reference data file that the server reads, you can use the following command.
  # kubectl cp ./http-server-ref/reference-data.json ref-data-server:/app/reference-data.json
  # # You can check the update on the server with this command. This may take some time to open the port.
  # kubectl port-forward ref-data-server 8001:8001
}

wait_for_datasets() {
  # Wait for the datasets to be ready
  wait_for_readiness "dataset/dataset-reference-data" ${TIMEOUT}
  wait_for_readiness "dataset/dataset-shift-history-totals" ${TIMEOUT}
  echo "Datasets have successfully been provisioned."
}

apply_server_and_pipelines() {
  # Apply the pipelines
  kubectl apply -k .
  kubectl get pipelines -n azure-iot-operations
}

wait_for_pipelines() {
  # Wait for the datasets to be ready
  wait_for_readiness "pipelines/pipeline-current-shift-counts" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-reference-data-load" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-shift-history-list" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-shift-history-totals-load" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-total-counter" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-zurich-validation" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-zurich-validation-debug" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-http-reference-data-load" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-machine-status" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-metrics-to-grafana" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-refdata-list" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-zurich-simulator-machine-status" ${TIMEOUT}
  wait_for_readiness "pipelines/pipeline-preprocess-opcua-payload" ${TIMEOUT}
  echo "Pipelines have successfully been provisioned."
}

verify_prereq_tools_installed
navigate_to_deployments_folder
build_and_push_http_server
apply_datasets
wait_for_datasets
apply_server_and_pipelines
wait_for_pipelines


