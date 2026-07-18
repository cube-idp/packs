# argo-events starter pack

Argo Events — the event-driven autonomy framework for Kubernetes (event
sources, event buses, and sensors that trigger Kubernetes-native workloads).
Pinned to the upstream release manifests (`v1.9.11`, images
`quay.io/argoproj/argo-events:v1.9.11`) in namespace `argo-events`. No gateway
exposure: argo-events has no user-facing UI in this pack — you use it through
the Kubernetes API by creating `EventSource`, `EventBus`, and `Sensor` custom
resources in the `argoproj.io` group.

## Manifests kind — CRDs and controllers in one pack

This is a manifests-kind pack: the upstream release manifests install the Argo
Events CRDs (`EventBus`, `EventSource`, `Sensor`), RBAC, the
`argo-events-controller-config` ConfigMap, the `controller-manager`
Deployment, and the `events-webhook` Deployment + Service in one shot. There
is no chart and no helm values. Because the operator ships its own CRDs *and*
the controllers that consume them inside a single pack, there is no cross-pack
CRD ordering dependency — the pack installs and reports Ready on its own.

## Two upstream files

Unlike most manifests packs, argo-events splits its release into two files,
**both** vendored here because both are needed to satisfy the health gate:

- `install.yaml` → `manifests/20-install.yaml` — CRDs, controller RBAC, the
  controller config ConfigMap, and the `controller-manager` Deployment.
- `install-validating-webhook.yaml` → `manifests/30-webhook.yaml` — the
  `events-webhook` ServiceAccount + RBAC, its `events-webhook` Service, and
  the `events-webhook` Deployment. This is a distinct upstream asset (not part
  of `install.yaml`); without it the `events-webhook` Deployment the health
  gate requires would never exist.

## Health gate

The engine reports the pack Ready once **both** the `controller-manager` and
the `events-webhook` Deployments in the `argo-events` namespace are Available.
`cube-idp status --exit-status` is green only then.

## Namespaces — vendored verbatim, no transformer needed

Unlike argo-rollouts (which needs a kustomize namespace transformer because
its upstream omits per-object namespaces), argo-events upstream **already
stamps** `metadata.namespace: argo-events` on every namespaced object
(ServiceAccounts, ConfigMap, Services, both Deployments) and on every
ClusterRoleBinding subject. cube-idp's delivery path (rendered objects → OCI
artifact → Flux `Kustomization` with no `targetNamespace`) therefore applies
them straight into `argo-events` — so `20-install.yaml` and `30-webhook.yaml`
are byte-identical to the pristine upstream files below their provenance
headers (no transformation at all). Cluster-scoped objects (3 CRDs, 5
ClusterRoles, 2 ClusterRoleBindings) correctly carry no namespace.
`imagePullPolicy` is left verbatim (nothing stripped or flipped).

## Layout

- `manifests/10-namespace.yaml` — the vendored upstream files do not ship a
  `Namespace` object, so it is added here (namespace-first, copying argocd's
  layout).
- `manifests/20-install.yaml` — the vendored `install.yaml`, verbatim below
  its header. Do not edit by hand; re-vendor per "Re-vendoring".
- `manifests/30-webhook.yaml` — the vendored `install-validating-webhook.yaml`,
  verbatim below its header. Do not edit by hand; re-vendor per "Re-vendoring".

## Re-vendoring (version bumps)

Both manifest files are vendored verbatim (no transformation). To bump the
pinned version, refetch both upstream assets and re-prepend the header comment
block (the browser-download path may 302 to an error page under load; the API
asset endpoint is reliable):

```bash
VERSION=v1.9.11   # <- new pin
WORK=$(mktemp -d)
for ASSET in install.yaml install-validating-webhook.yaml; do
  AID=$(gh api repos/argoproj/argo-events/releases/tags/${VERSION} \
    --jq ".assets[] | select(.name==\"${ASSET}\") | .id")
  gh api -H "Accept: application/octet-stream" \
    repos/argoproj/argo-events/releases/assets/${AID} > "$WORK/${ASSET}"
  sha256sum "$WORK/${ASSET}"   # record in the header + FINDINGS
done
# Re-prepend each file's existing header comment block over the fresh bytes:
{ sed -n '/^#/p;/^[^#]/q' packs/argo-events/manifests/20-install.yaml; \
  cat "$WORK/install.yaml"; } > packs/argo-events/manifests/20-install.yaml
{ sed -n '/^#/p;/^[^#]/q' packs/argo-events/manifests/30-webhook.yaml; \
  cat "$WORK/install-validating-webhook.yaml"; } > packs/argo-events/manifests/30-webhook.yaml
```

Then update the version + sha256 references in this README and in both headers,
and re-run conformance (`bash hack/conformance.sh argo-events <cube-idp-binary>`).

## Verification method

No chart involved, so "verify against helm show values" doesn't apply here;
instead the vendored manifests were inspected directly: confirmed both images
are `quay.io/argoproj/argo-events:v1.9.11`, that neither upstream file ships a
`Namespace` object, that every namespaced object and every ClusterRoleBinding
subject already carries `namespace: argo-events`, that no cluster-scoped object
has a namespace, and that both required Deployments (`controller-manager`,
`events-webhook`) are present.

- `install.yaml`
  - URL: `https://github.com/argoproj/argo-events/releases/download/v1.9.11/install.yaml`
  - Version: `v1.9.11`
  - sha256 (pristine upstream): `affaae84d8d5e5c967048815d8331b7a0b66bc0ae81f81bc47c7e0b2281ebc86`
- `install-validating-webhook.yaml`
  - URL: `https://github.com/argoproj/argo-events/releases/download/v1.9.11/install-validating-webhook.yaml`
  - Version: `v1.9.11`
  - sha256 (pristine upstream): `4b7fd345dc2ca6ab2a963eaaf6841bf6702d95da00be318b301a1d2b87c2f163`
