# kyverno starter pack

Kyverno — the Kubernetes-native policy engine: validate, mutate, generate,
and clean up resources with policies that are themselves Kubernetes
resources. Pinned to `kyverno/kyverno` `3.8.2` (app `v1.18.2`, images
`reg.kyverno.io/kyverno/{kyvernopre,kyverno,background-controller,
cleanup-controller,reports-controller}:v1.18.2`) in namespace `kyverno`.
No gateway exposure: kyverno has no UI — you use it through the Kubernetes
API (its policy CRDs) and admission webhooks.

## What's installed

The four controller Deployments — `kyverno-admission-controller` (with
its `kyvernopre` init container), `kyverno-background-controller`,
`kyverno-cleanup-controller`, `kyverno-reports-controller` — plus their
RBAC, Services, ConfigMaps, and 22 CRDs (kyverno's own and the
`kyverno-api` subchart's) rendered from the chart's `crds` subcharts
(`crds.install` defaults `true`). The engine reports the pack Ready once
all four deployments are Available. Optional chart extras stay off at
their defaults: no grafana dashboard, no reports-server, no openreports.

## No hooks fire on install

The chart's hooks are helm-test, post-upgrade `migrate-resources`, and
pre-delete webhook/scale cleanup jobs — none is install-relevant, so the
contract's hook handling skips them all and the rendered artifact is
plain static objects.

## No policies included

Kyverno ships with zero policies: installing this pack changes nothing
about admission until policies exist. Curated Pod Security Standards
baseline policies are the separate `kyverno-policies` pack, so they stay
optional.

## Values

Per-controller replica knobs are schema-checked by `pack.cue`:
`admissionController.replicas`, `backgroundController.replicas`,
`cleanupController.replicas`, `reportsController.replicas` (each
`int > 0`; the chart default is unset, which Kubernetes runs as 1). Note
kyverno documents `3` as the supported replica count for an HA admission
controller. The schema is open — any other kyverno chart value
(`features`, `config`, `cleanupJobs`, …) passes through to the helm
render unvalidated.
