metadata description = 'This template deploys Azure IoT Operations.'

/*****************************************************************************/
/*                          Deployment Parameters                            */
/*****************************************************************************/
@description('Name of the existing arc-enabled cluster where AIO will be deployed.')
param clusterName string

@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'westus3'
  'westeurope'
  'northeurope'
  'eastus2euap'
])
@description('Location of the existing arc-enabled cluster where AIO will be deployed.')
param clusterLocation string = location

@allowed([
  'eastus'
  'eastus2'
  'westus'
  'westus2'
  'westus3'
  'westeurope'
  'northeurope'
  'eastus2euap'
])
@description('Location of where ARM resources will be deployed to. The default is where the resource group is located.')
param location string = any(resourceGroup().location)

@description('Name of the custom location where AIO will be deployed. The default is the cluster name suffixed with "-cl".')
param customLocationName string = '${clusterName}-cl'

@description('Name of a specific deployment environment, such as a Kubernetes cluster or an edge device. The default is the cluster name suffixed with "-target".')
param targetName string = '${toLower(clusterName)}-target'

@description('Name of data processor instance. The default is the cluster name suffixed with "-processor".')
param dataProcessorInstanceName string = '${toLower(clusterName)}-processor'

@description('Data Processor secrets.')
#disable-next-line secure-secrets-in-params
param dataProcessorSecrets object = {
  secretProviderClassName: 'aio-default-spc'
  servicePrincipalSecretRef: 'aio-akv-sp'
}

@description('MQ secrets.')
#disable-next-line secure-secrets-in-params
param mqSecrets object = {
  enabled: true
  secretProviderClassName: 'aio-default-spc'
  servicePrincipalSecretRef: 'aio-akv-sp'
}

@description('Data Processor cardinality.')
param dataProcessorCardinality object = {
  readerWorker: 1
  runnerWorker: 1
  messageStore: 1
}

@description('Flag to enable resource sync rules. The default is true.')
param deployResourceSyncRules bool = true

/*****************************************************************************/
/*                                Constants                                  */
/*****************************************************************************/

var AIO_CLUSTER_RELEASE_NAMESPACE = 'azure-iot-operations'

var AIO_EXTENSION_SCOPE = {
  cluster: {
    releaseNamespace: AIO_CLUSTER_RELEASE_NAMESPACE
  }
}

var AIO_TRUST_CONFIG_MAP = 'aio-ca-trust-bundle-test-only'
var AIO_TRUST_ISSUER = 'aio-ca-issuer'
var AIO_TRUST_SECRET_NAME = 'aio-ca-key-pair-test-only'

var OBSERVABILITY = {
  genevaCollectorAddressNoProtocol: 'geneva-metrics-service.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
  otelCollectorAddressNoProtocol: 'aio-otel-collector.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
  otelCollectorAddress: 'http://aio-otel-collector.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
  genevaCollectorAddress: 'http://geneva-metrics-service.${AIO_CLUSTER_RELEASE_NAMESPACE}.svc.cluster.local:4317'
}

// Note: Do NOT update the keys of this object. The AIO Portal Wizard depends on the
// format of this object. Updating keys will break the UI.
var VERSIONS = {
  adr: '0.1.0-preview'
  opcUaBroker: '0.2.0-preview'
  observability: '0.1.0-preview'
  akri: '0.1.0-preview'
  mq: '0.2.0-preview'
  aio: '0.3.0-preview'
  layeredNetworking: '0.1.0-preview'
  processor: '0.1.2-preview'
  dapr: '1.10.9'
}

var TRAINS = {
  mq: 'preview'
  aio: 'preview'
  processor: 'preview'
  adr: 'preview'
  akri: 'preview'
  layeredNetworking: 'preview'
  dapr: 'stable'
  opcUaBroker: 'preview'
}

var MQ_PROPERTIES = {
  domain: 'aio-mq-dmqtt-frontend.${AIO_CLUSTER_RELEASE_NAMESPACE}'
  port: 8883
  localUrl: 'mqtts://aio-mq-dmqtt-frontend.${AIO_CLUSTER_RELEASE_NAMESPACE}:8883'
  name: 'aio-mq-dmqtt-frontend'
  satAudience: 'aio-mq'
}
/*****************************************************************************/
/*         Existing Arc-enabled cluster where AIO will be deployed.          */
/*****************************************************************************/

resource cluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: clusterName
}

/*****************************************************************************/
/*                     Azure IoT Operations Extensions.                      */
/*****************************************************************************/
resource aio_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'azure-iot-operations'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.iotoperations'
    version: VERSIONS.aio
    releaseTrain: TRAINS.aio
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'rbac.cluster.admin': 'true'
      'aioTrust.enabled': 'true'
      'aioTrust.secretName': AIO_TRUST_SECRET_NAME
      'aioTrust.configmapName': AIO_TRUST_CONFIG_MAP
      'aioTrust.issuerName': AIO_TRUST_ISSUER
      'Microsoft.CustomLocation.ServiceAccount': 'default'
      otelCollectorAddress: OBSERVABILITY.otelCollectorAddressNoProtocol
      genevaCollectorAddress: OBSERVABILITY.genevaCollectorAddressNoProtocol
    }
  }
}

resource deviceRegistry_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'assets'
  properties: {
    extensionType: 'microsoft.deviceregistry.assets'
    version: VERSIONS.adr
    releaseTrain: TRAINS.adr
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'Microsoft.CustomLocation.ServiceAccount': 'default'
    }
  }
  dependsOn: [
    aio_extension
  ]
}

resource mq_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'mq'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.iotoperations.mq'
    version: VERSIONS.mq
    releaseTrain: TRAINS.mq
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'global.quickstart': 'false'
      'global.openTelemetryCollectorAddr': OBSERVABILITY.otelCollectorAddress
      'secrets.enabled': mqSecrets.enabled
      'secrets.secretProviderClassName': mqSecrets.secretProviderClassName
      'secrets.servicePrincipalSecretRef': mqSecrets.servicePrincipalSecretRef
    }
  }
  dependsOn: [
    aio_extension
  ]
}

resource dataProcessor_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'processor'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    extensionType: 'microsoft.iotoperations.dataprocessor'
    version: VERSIONS.processor
    releaseTrain: TRAINS.processor
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'Microsoft.CustomLocation.ServiceAccount': 'default'
      otelCollectorAddress: OBSERVABILITY.otelCollectorAddressNoProtocol
      genevaCollectorAddress: OBSERVABILITY.genevaCollectorAddressNoProtocol
      'cardinality.readerWorker.replicas': dataProcessorCardinality.readerWorker
      'cardinality.runnerWorker.replicas': dataProcessorCardinality.runnerWorker
      'nats.config.cluster.replicas': dataProcessorCardinality.messageStore
      'secrets.secretProviderClassName': dataProcessorSecrets.secretProviderClassName
      'secrets.servicePrincipalSecretRef': dataProcessorSecrets.servicePrincipalSecretRef
      'caTrust.enabled': 'true'
      'caTrust.configmapName': AIO_TRUST_CONFIG_MAP
      'serviceAccountTokens.MQClient.audience': MQ_PROPERTIES.satAudience
    }
  }
  dependsOn: [
    aio_extension
  ]
}

resource dapr_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'dapr'
  properties: {
    extensionType: 'microsoft.dapr'
    version: VERSIONS.dapr
    releaseTrain: TRAINS.dapr
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {
      'global.ha.enabled': 'false'
    }
  }
  dependsOn: [
    aio_extension
  ]
}

resource layeredNetworking_extension 'Microsoft.KubernetesConfiguration/extensions@2022-03-01' = {
  scope: cluster
  name: 'layered-networking'
  properties: {
    extensionType: 'microsoft.iotoperations.layerednetworkmanagement'
    version: VERSIONS.layeredNetworking
    releaseTrain: TRAINS.layeredNetworking
    autoUpgradeMinorVersion: false
    scope: AIO_EXTENSION_SCOPE
    configurationSettings: {}
  }
  dependsOn: [
    aio_extension
  ]
}
/*****************************************************************************/
/*            Azure Arc custom location and resource sync rules.             */
/*****************************************************************************/

resource customLocation 'Microsoft.ExtendedLocation/customLocations@2021-08-31-preview' = {
  name: customLocationName
  location: clusterLocation
  properties: {
    hostResourceId: cluster.id
    namespace: AIO_CLUSTER_RELEASE_NAMESPACE
    displayName: customLocationName
    clusterExtensionIds: [
      aio_extension.id
      mq_extension.id
      deviceRegistry_extension.id
      dataProcessor_extension.id
    ]
  }
}

resource orchestrator_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (deployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-aio-sync'
  location: clusterLocation
  properties: {
    priority: 100
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.iotoperationsorchestrator'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
}

resource dataProcessor_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (deployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-dp-sync'
  location: clusterLocation
  properties: {
    priority: 300
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.iotoperationsdataprocessor'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
  dependsOn: [
    orchestrator_syncRule
  ]
}

resource mq_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (deployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-mq-sync'
  location: clusterLocation
  properties: {
    priority: 400
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'microsoft.iotoperationsmq'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
  dependsOn: [
    dataProcessor_syncRule
  ]
}

resource deviceRegistry_syncRule 'Microsoft.ExtendedLocation/customLocations/resourceSyncRules@2021-08-31-preview' = if (deployResourceSyncRules) {
  parent: customLocation
  name: '${customLocationName}-adr-sync'
  location: clusterLocation
  properties: {
    priority: 200
    selector: {
      matchLabels: {
        #disable-next-line no-hardcoded-env-urls
        'management.azure.com/provider-name': 'Microsoft.DeviceRegistry'
      }
    }
    targetResourceGroup: resourceGroup().id
  }
  dependsOn: [
    mq_syncRule
  ]
}

/*****************************************************************************/
/*               Azure IoT Operations Data Processor Instance.               */
/*****************************************************************************/

resource processorInstance 'Microsoft.IoTOperationsDataProcessor/instances@2023-10-04-preview' = {
  name: dataProcessorInstanceName
  location: location
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {}
  dependsOn: [
    dataProcessor_syncRule
  ]
}

/*****************************************************************************/
/*     Deployment of Helm Charts and CRs to run on Arc-enabled cluster.      */
/*****************************************************************************/

var observability_helmChart = {
  name: 'aio-observability'
  type: 'helm.v3'
  properties: {
    chart: {
      repo: 'mcr.microsoft.com/azureiotoperations/helm/aio-opentelemetry-collector'
      version: VERSIONS.observability
    }
    values: {
      mode: 'deployment'
      fullnameOverride: 'aio-otel-collector'
      config: {
        processors: {
          memory_limiter: {
            limit_percentage: 80
            spike_limit_percentage: 10
            check_interval: '60s'
          }
        }
        receivers: {
          jaeger: null
          prometheus: null
          zipkin: null
          otlp: {
            protocols: {
              grpc: {
                endpoint: ':4317'
              }
              http: {
                endpoint: ':4318'
              }
            }
          }
        }
        exporters: {
          prometheus: {
            endpoint: ':8889'
            resource_to_telemetry_conversion: {
              enabled: true
            }
          }
        }
        service: {
          extensions: [
            'health_check'
          ]
          pipelines: {
            metrics: {
              receivers: [
                'otlp'
              ]
              exporters: [
                'prometheus'
              ]
            }
            logs: null
            traces: null
          }
          telemetry: null
        }
        extensions: {
          memory_ballast: {
            size_mib: 0
          }
        }
      }
      resources: {
        limits: {
          cpu: '100m'
          memory: '512Mi'
        }
      }
      ports: {
        metrics: {
          enabled: true
          containerPort: 8889
          servicePort: 8889
          protocol: 'TCP'
        }
        'jaeger-compact': {
          enabled: false
        }
        'jaeger-grpc': {
          enabled: false
        }
        'jaeger-thrift': {
          enabled: false
        }
        zipkin: {
          enabled: false
        }
      }
    }
  }
}


resource target 'Microsoft.IoTOperationsOrchestrator/Targets@2023-10-04-preview' = {
  name: targetName
  location: location
  extendedLocation: {
    name: customLocation.id
    type: 'CustomLocation'
  }
  properties: {
    scope: AIO_CLUSTER_RELEASE_NAMESPACE
    version: deployment().properties.template.contentVersion
    components: [
      observability_helmChart
    ]
    topologies: [
      {
        bindings: [
          {
            role: 'helm.v3'
            provider: 'providers.target.helm'
            config: {
              inCluster: 'true'
            }
          }
          {
            role: 'yaml.k8s'
            provider: 'providers.target.kubectl'
            config: {
              inCluster: 'true'
            }
          }
        ]
      }
    ]
  }
  dependsOn: [
    orchestrator_syncRule
  ]
}

/*****************************************************************************/
/*                          Deployment Outputs                               */
/*****************************************************************************/

output customLocationId string = customLocation.id
output customLocationName string = customLocationName
output targetName string = targetName
output processorInstanceName string = processorInstance.name
output aioNamespace string = AIO_CLUSTER_RELEASE_NAMESPACE
output mq object = MQ_PROPERTIES
output observability object = OBSERVABILITY
