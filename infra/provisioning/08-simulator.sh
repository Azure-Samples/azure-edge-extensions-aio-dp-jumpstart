#!/bin/bash

# Variables
REPO_URL="https://github.com/Azure-Samples/explore-iot-operations"
REPO_DIR="explore-iot-operations"
TARGET_FOLDER="samples/industrial-data-simulator"
IMAGE_NAME="k3d-devregistry.localhost:5500/local-industrial-data-simulator:latest"
TMP_DIR="tmp"

# Create a temporary directory if it doesn't exist
mkdir -p $TMP_DIR

# Navigate to the temporary directory
pushd $TMP_DIR

# Clone the repository
git clone $REPO_URL $REPO_DIR

# Navigate to the target folder
pushd $REPO_DIR

# Compile the code if needed (assuming it's necessary)
# Add compilation commands here if required

# Build Docker image
docker build . -f samples/industrial-data-simulator/Dockerfile --tag $IMAGE_NAME
docker push $IMAGE_NAME

popd
popd

kubectl apply -f ./deploy/simulator-counter.yaml

# Cleanup
rm -rf ./tmp