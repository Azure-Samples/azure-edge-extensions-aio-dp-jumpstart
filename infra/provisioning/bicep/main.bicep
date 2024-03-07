// Based in https://github.com/Azure/azure-iot-operations-pr/blob/main/.integration-lab/environments/personal/example.bicep

@description('Resource group where the resources will be deployed.')
param resourceGroup string

@description('Name of the cluster registered in Azure Arc.')
param clusterName string

@description('Name of the location where the resources will be deployed.')
param location string

@description('Name of the location where the resources will be deployed.')
param clusterLocation string = location

@description('Name of the deployment.')
param deploymentName string = 'aio-${resourceGroup}'

@description('Subscription ID where the resources will be deployed.')
param subscriptionId string = subscription().subscriptionId 

@description('Hash to make the deployment name unique.')
param hash string = utcNow('yyyyMMddHHmmss')

// When referencing the template to deploy, use the relative path to the template from the location
// of this file.  For example, if you copy this file to the root of the repo, you would use
// 'dev/azure-iot-operations.bicep' to reference the dev template.
module myDeployment 'azure-iot-operations.bicep' = {
  name: '${deploymentName}-${hash}'
  #disable-next-line explicit-values-for-loc-params
  params: {
    clusterName: clusterName
    location: location
    clusterLocation: clusterLocation
    //opcuaDiscoveryEndpoint: '<opcuaDiscoveryEndpoint>'
  }
  scope: az.resourceGroup(subscriptionId, resourceGroup)
}
