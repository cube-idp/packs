# cloudnativepg starter pack

CloudNativePG — the Kubernetes operator for running PostgreSQL. Pinned to
the upstream release manifest `cnpg-1.30.0.yaml` (`v1.30.0`, operator image
`ghcr.io/cloudnative-pg/cloudnative-pg:1.30.0`) in namespace `cnpg-system`.
No gateway exposure: the operator has no UI — you use it through the
Kubernetes API by creating `Cluster` (and `Backup`, `ScheduledBackup`, …)
custom resources in the `postgresql.cnpg.io` group.

## Manifests kind — CRDs and controller in one pack

This is a manifests-kind pack: the upstream release manifest installs the
CloudNativePG CRDs, RBAC, webhook configuration, and the
`cnpg-controller-manager` Deployment in one shot. There is no chart and no
helm values. Because the operator ships its own CRDs *and* the controller
that consumes them inside a single pack, there is no cross-pack CRD
ordering dependency — the pack installs and reports Ready on its own.

## Health gate

The engine reports the pack Ready once the `cnpg-controller-manager`
Deployment in `cnpg-system` is Available. `cube-idp status --exit-status`
is green only then.

## Vendoring

`manifests/10-cnpg.yaml` is the upstream `cnpg-1.30.0.yaml` release
manifest, byte-verbatim below its provenance comment header (nothing
stripped, nothing added — upstream already ships the `cnpg-system`
Namespace as its first object). Re-vendor by re-downloading the pinned URL
and verifying the recorded sha256:

- URL: `https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v1.30.0/cnpg-1.30.0.yaml`
- Version: `v1.30.0`
- sha256: `f8bede43fe4ee0d478c2355b204a36876b2ae4faac60f2a9452280b293da3b88`
