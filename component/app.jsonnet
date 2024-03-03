local kap = import 'lib/kapitan.libjsonnet';
local inv = kap.inventory();
local params = inv.parameters.sentry_metrics;
local argocd = import 'lib/argocd.libjsonnet';

local app = argocd.App('sentry-metrics', params.namespace);

{
  'sentry-metrics': app,
}
