local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.sentry_metrics;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('sentry-metrics', params.namespace.name);

{
  'sentry-metrics': app {
    spec+: {
      syncPolicy+: {
        syncOptions+: [
          'ServerSideApply=true',
        ],
      },
      ignoreDifferences: [ {
        group: 'apps',
        kind: 'StatefulSet',
        jsonPointers: [
          '/spec/volumeClaimTemplates/0/apiVersion',
          '/spec/volumeClaimTemplates/0/kind',
        ],
      } ],
    },
  },
}
