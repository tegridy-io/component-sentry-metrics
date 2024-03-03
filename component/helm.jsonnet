local com = import 'lib/commodore.libjsonnet';
local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();

// The hiera parameters for the component
local params = inv.parameters.sentry_metrics;

local topologySpreadConstraints = {
  maxSkew: 1,
  topologyKey: 'kubernetes.io/hostname',
  whenUnsatisfiable: 'DoNotSchedule',
};

local components = {
  fullnameOverride: 'mimir',
  global: {
    extraEnvFrom: [
      {
        secretRef: {
          name: params.global.bucketName,
        },
      },
    ],
  },
  mimir: {
    structuredConfig: params.config,
  },
  // ----- Monitoring -------------------------------------------------------
  metaMonitoring: {
    serviceMonitor: {
      enabled: false,
    },
    prometheusRule: {
      enabled: false,
      mimirAlerts: false,
      mimirRules: false,
    },
    grafanaAgent: {
      enabled: false,
    },
  },
  // ------ Ingress ------------------------------------------------------------
  gateway: {
    [if params.ingress.enabled then 'ingress']: {
      enabled: true,
      annotations: params.ingress.annotations,
      hosts: [ {
        host: params.ingress.url,
        paths: [ {
          path: '/',
          pathType: 'Prefix',
        } ],
      } ],
      [if params.ingress.tls then 'tls']: [ {
        secretName: 'mimir-gateway-tls',
        hosts: [ params.ingress.url ],
      } ],
    },
    nginx: {
      verboseLogging: false,
      //   basicAuth: {
      //     enabled: true,
      //     htpasswd: '',
      //   },
    },
  },
};

local others = {
  // ----- Read path --------------------------------------------------------
  querier: {
    enabled: true,
    replicas: params.components.querier.replicas,
    resources: params.components.querier.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  query_frontend: {
    enabled: true,
    replicas: params.components.queryFrontend.replicas,
    resources: params.components.queryFrontend.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  store_gateway: {
    enabled: true,
    replicas: params.components.storeGateway.replicas,
    resources: params.components.storeGateway.resources,
    topologySpreadConstraints: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.global.storageClass,
    },
    zoneAwareReplication: {
      enabled: false,
    },
  },
  // ----- Write path -------------------------------------------------------
  distributor: {
    enabled: true,
    replicas: params.components.distributor.replicas,
    resources: params.components.distributor.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  ingester: {
    enabled: true,
    replicas: params.components.ingester.replicas,
    resources: params.components.ingester.resources,
    topologySpreadConstraints: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.global.storageClass,
    },
    zoneAwareReplication: {
      enabled: false,
    },
  },
  // ----- Backend ----------------------------------------------------------
  compactor: {
    enabled: true,
    replicas: params.components.compactor.replicas,
    resources: params.components.compactor.resources,
    topologySpreadConstraints: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.global.storageClass,
    },
  },
  gateway: {
    enabledNonEnterprise: true,
    replicas: params.components.gateway.replicas,
    resources: params.components.gateway.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  // ----- Optional ---------------------------------------------------------
  ruler: {
    enabled: params.components.ruler.enabled,
    replicas: params.components.ruler.replicas,
    resources: params.components.ruler.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  query_scheduler: {
    enabled: params.components.queryScheduler.enabled,
    replicas: params.components.queryScheduler.replicas,
    resources: params.components.queryScheduler.resources,
    topologySpreadConstraints: topologySpreadConstraints,
  },
  alertmanager: {
    enabled: params.components.alertmanager.enabled,
    replicas: params.components.alertmanager.replicas,
    resources: params.components.alertmanager.resources,
    topologySpreadConstraints: topologySpreadConstraints,
    persistentVolume: {
      storageClass: params.global.storageClass,
    },
    zoneAwareReplication: {
      enabled: false,
    },
  },
  // ----- Disabled ---------------------------------------------------------
  overrides_exporter: {
    enabled: false,
  },
  minio: {
    enabled: false,
  },
  rollout_operator: {
    enabled: false,
  },
  nginx: {
    enabled: false,
  },
};

{
  'values-components': components,
  'values-others': others,
}
