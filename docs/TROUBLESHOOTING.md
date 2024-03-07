# Troubleshooting Guide

This guide provides solutions for common issues you may encounter.

## Problem 1: Custom Location OID cannot be retrieved

### Symptom for Problem 1

When running `az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid $ARC_CUSTOMLOCATION_OID --features cluster-connect custom-locations`, you may receive the following:

"WARNING: Unable to fetch the Object ID of the Azure AD application used by Azure Arc service. Unable to enable the 'custom-locations' feature. Insufficient privileges to complete the operation."

"Unable to fetch the Object ID of the Azure AD application used by Azure Arc service. Proceeding with the Object ID provided to enable the 'custom-locations' feature."

### Cause for Problem 1

Most likely the cause is when using service principal.

When using service principal, as we do in Github Actions workflow, the Object ID for custom locations feature is not retrievable when running `az connectedk8s enable-features`. This will then use the parameter --custom-locations-oid, and therefore needs to be correct.

When using user account, you will not get the same issue as it is able to retrieve the oid, when running `az connectedk8s enable-features`. 

### Solution for Problem 1

To resolve this issue for Service Principal in GitHub Actions follow the steps described [here](https://learn.microsoft.com/en-us/azure/azure-arc/kubernetes/custom-locations#enable-custom-locations-on-your-cluster).

Follow steps:

1. Login to your user account
1. Retrieve OID with the command

   ```bash
        # Azure CLI version lower than 2.37.0
        az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query objectId -o tsv

        # Azure CLI version 2.37.0 or higher
        az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
    ```

1. Save that as Github Secret for your Github Actions
1. Pass it as a value for the parameter --custom-locations-oid for the below command in your pipeline.

    ```bash
        az connectedk8s enable-features -n $CLUSTER_NAME -g $RESOURCE_GROUP --custom-locations-oid $ARC_CUSTOMLOCATION_OID --features cluster-connect custom-locations
    ```

## Problem 2: Data Processor failing to spin up for K3D cluster

### Symptom for Problem 2

When deploying Data Processor pods, after AIO deployment for a K3d cluster, you may get them in a failure state. 
You may also notice that the csi driver pod is failing.

When describing the csi driver pod, you may get this error:

"Error: failed to generate container "3d4ad3c176b527b70565218bacf3383524aca874345983350aae6a8160aa0fdb" spec: failed to 
generate spec: path "/var/lib/kubelet/pods" is mounted on "/var/lib/kubelet" but it is not a shared mount"

### Cause for Problem 2

The problem is that by default your K3d cluster do not have shared mounts enabled needed for the csi driver. 
See github issue [here](https://github.com/k3d-io/k3d/issues/1063)

### Solution for Problem 2

Before creating your K3d cluster, set the environment variable as below:

```bash
    export K3D_FIX_MOUNTS=1
```

## Problem 3: Kubernetes pods failures in Github Action

### Symptom for Problem 3

You may get failures in `AIO - Validate Pull Request` Github Actions Workflow during deployment of AIO components.
Failures in deployments of AIO components may be difficult to troubleshoot if the errors are in the pods deployed like [Problem #1](#problem-1-custom-location-oid-cannot-be-retrieved). 

### Cause for Problem 3

The cause is that the virtual machine is used for Pipelines spin down after running. Therefore, you may not be able to connect to the cluster and inspect pods as the cluster will go down with the virtual machine.

### Solution for Problem 3

One way to troubleshoot is to use [self-hosted vms](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) instead so the vm does not spin down.

## Problem 4: Cannot clean dataset records

### Symptom for Problem 4

You may run into an an issue where you cannot delete records from AIO dataset. 
This is an issue when you are testing and want a clean dataset to work with.

### Cause for Problem 4

Dataset currently cannot be updated or deleted. This feedback was given to Product Group. Records in dataset will be deleted on the TTL defined for that dataset.


### Solution for Problem 4

You can create a new dataset to be referenced in your pipelines to start with zero records. There is a kustomize file [here](../infra/deployment/dp-pipelines/kustomization.yaml) that you can use by uncommenting the lines so that a new dataset is applied with TTL of only 5 minutes. You can update it as you wish and use different datasets for your testing. To apply it, you will need to run:

```bash
    # From project root directory
    kubectl apply -k ./infra/deployment/dp-pipelines
```
