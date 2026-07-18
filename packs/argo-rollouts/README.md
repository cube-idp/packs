# argo-rollouts starter pack

Argo Rollouts — the Kubernetes progressive-delivery controller (canary and
blue-green deployments, analysis, experiments). Pinned to the upstream
release `install.yaml` (`v1.9.1`, controller image
`quay.io/argoproj/argo-rollouts:v1.9.1`) in namespace `argo-rollouts`. No
gateway exposure: the controller has no UI in this pack — you use it through
the Kubernetes API by creating `Rollout` (and `AnalysisTemplate`,
`Experiment`, …) custom resources in the `argoproj.io` group. (The optional
argo-rollouts dashboard ships as a separate `dashboard-install.yaml` upstream
and is not vendored here.)

## Manifests kind — CRDs and controller in one pack

This is a manifests-kind pack: the upstream release manifest installs the
Argo Rollouts CRDs (5), RBAC, the `argo-rollouts-config` ConfigMap, the
metrics Service, and the `argo-rollouts` controller Deployment in one shot.
There is no chart and no helm values. Because the controller ships its own
CRDs *and* the controller that consumes them inside a single pack, there is
no cross-pack CRD ordering dependency — the pack installs and reports Ready
on its own.

## Health gate

The engine reports the pack Ready once the `argo-rollouts` Deployment in the
`argo-rollouts` namespace is Available. `cube-idp status --exit-status` is
green only then.

## Explicit `namespace: argo-rollouts` on every namespaced object

Upstream's `install.yaml` deliberately omits `metadata.namespace` and
assumes `kubectl apply -n argo-rollouts`. cube-idp's delivery path (rendered
objects → OCI artifact → Flux `Kustomization` with no `targetNamespace`)
applies objects exactly as rendered — an object without an explicit namespace
would land in `default`. The vendored file is therefore regenerated through
kustomize's namespace transformer so all namespaced objects (ServiceAccount,
ConfigMap, Secret, Service, Deployment) carry `namespace: argo-rollouts`,
while cluster-scoped objects (5 CRDs, 4 ClusterRoles, 1 ClusterRoleBinding)
stay un-namespaced and the ClusterRoleBinding subject correctly references
`namespace: argo-rollouts`. `imagePullPolicy` is left verbatim (nothing
stripped or flipped).

## Layout

- `manifests/10-namespace.yaml` — the vendored `install.yaml` does not ship a
  `Namespace` object, so it is added here (namespace-first, copying argocd's
  layout).
- `manifests/20-install.yaml` — the vendored install manifest, transformed
  (namespace transformer only, see above). Do not edit by hand; regenerate
  per "Re-vendoring".

## Re-vendoring (version bumps)

`manifests/20-install.yaml` is generated, not hand-edited. To bump the pinned
version, rerun (any recent `kubectl`; its embedded kustomize handles the
namespace transformer, correctly skipping cluster-scoped kinds):

```bash
VERSION=v1.9.1   # <- new pin
WORK=$(mktemp -d)
# fetch the release asset (the browser-download path may 302 to an error
# page under load; the API asset endpoint is reliable):
AID=$(gh api repos/argoproj/argo-rollouts/releases/tags/${VERSION} \
  --jq '.assets[] | select(.name=="install.yaml") | .id')
gh api -H "Accept: application/octet-stream" \
  repos/argoproj/argo-rollouts/releases/assets/${AID} > "$WORK/upstream-install.yaml"
sha256sum "$WORK/upstream-install.yaml"   # record in the header + FINDINGS
cat > "$WORK/kustomization.yaml" <<'EOF'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: argo-rollouts
resources:
  - upstream-install.yaml
EOF
kubectl kustomize "$WORK" > "$WORK/rendered.yaml"
# keep the explanatory header comment block from the current file:
{ sed -n '/^#/p;/^[^#]/q' packs/argo-rollouts/manifests/20-install.yaml; \
  cat "$WORK/rendered.yaml"; } > packs/argo-rollouts/manifests/20-install.yaml
```

Then update the version + sha256 references in this README and in the header,
and re-run conformance (`bash hack/conformance.sh argo-rollouts <cube-idp-binary>`).

## Verification method

No chart involved, so "verify against helm show values" doesn't apply here;
instead the vendored `install.yaml` was inspected directly: confirmed the
controller image `quay.io/argoproj/argo-rollouts:v1.9.1`, that no `Namespace`
object ships in the upstream manifest, and (post-kustomize) that all
namespaced objects carry `namespace: argo-rollouts`, no cluster-scoped object
gained a namespace, and the ClusterRoleBinding subject references
`namespace: argo-rollouts`.

- URL: `https://github.com/argoproj/argo-rollouts/releases/download/v1.9.1/install.yaml`
- Version: `v1.9.1`
- sha256 (pristine upstream): `78c82343803c2bbc13a36049e269a532dd67f25b7e2cb3603c99e31d8d8a40b5`
