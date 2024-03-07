#!/bin/bash

set -e

verify_prereq_tools_installed() {
    # Check if kubectl is installed
  if ! command -v kubectl &> /dev/null
  then
      echo "Kubectl could not be found. Please install it and try again."
      exit
  fi
}

navigate_to_deployments_folder() {
  SCRIPT_DIR=$(dirname "$0")
  cd $SCRIPT_DIR
}

delete_datasets_and_pipelines() {
  # Delete the datasets and pipelines
  kubectl delete dataset --all -n azure-iot-operations
  kubectl delete pipeline --all -n azure-iot-operations
}

verify_prereq_tools_installed
navigate_to_deployments_folder
delete_datasets_and_pipelines