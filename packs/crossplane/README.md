# crossplane starter pack

Crossplane core — the control plane framework for assembling
infrastructure and exposing self-service platform APIs. Pinned to
`crossplane-stable/crossplane` `2.3.3` (app `v2.3.3`, image
`xpkg.crossplane.io/crossplane/crossplane:v2.3.3`) in namespace
`crossplane-system`. No gateway exposure: crossplane has no UI — you use
it through the Kubernetes API (its CRDs).

## Core only — providers are separate packs

Per the Phase 5 design (decision 5) this pack installs the crossplane
core only: the `crossplane` and `crossplane-rbac-manager` deployments,
their RBAC, and the webhook TLS secrets. No Providers, no Configurations,
no Functions are preinstalled — install them as crossplane packages
(`pkg.crossplane.io`) yourself, or wait for the dedicated provider packs
a later phase adds. `provider.defaultActivations` keeps the chart default
(`["*"]`).

## CRDs install at runtime, not from the chart

The chart ships no CRD manifests: the crossplane pod's init container
installs and upgrades the core CRDs (`providers.pkg.crossplane.io`,
`compositions.apiextensions.crossplane.io`, …) when it starts. First
readiness therefore includes that init pass; the engine reports the pack
Ready once both deployments are Available.

## Values

`values.replicas` (default `1`) scales the core pod and is schema-checked
by `pack.cue`. Any other chart value passes through unvalidated — the
RBAC manager's replica count, for example, is `rbacManager.replicas`.
