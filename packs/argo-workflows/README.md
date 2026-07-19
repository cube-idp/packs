# argo-workflows starter pack

Argo Workflows — the container-native workflow engine for Kubernetes: run
parallel jobs as DAGs or step sequences via `Workflow`, `CronWorkflow`, and
`WorkflowTemplate` custom resources in the `argoproj.io` group. Pinned to the
upstream release manifests (`v4.0.7`, images
`quay.io/argoproj/workflow-controller:v4.0.7` and
`quay.io/argoproj/argocli:v4.0.7`) in namespace `argo`.

The Argo Server UI/API is exposed at `https://workflows.${GATEWAY_HOST}`.

## Manifests kind — CRDs and controllers in one pack

This is a manifests-kind pack: the upstream release `install.yaml` (the
**cluster-install** variant) installs the Argo Workflows CRDs, RBAC, the
`workflow-controller` Deployment, and the `argo-server` Deployment + Service in
one shot. There is no chart and no helm values. Because the operator ships its
own CRDs *and* the controllers that consume them inside a single pack, there is
no cross-pack CRD ordering dependency — the pack installs and reports Ready on
its own.

## Health gate

The engine reports the pack Ready once **both** the `workflow-controller` and
the `argo-server` Deployments in the `argo` namespace are Available.
`cube-idp status --exit-status` is green only then.

## Expose — the Argo Server

`pack.cue`'s `expose` block records `https://workflows.${GATEWAY_HOST}` as the
D11 discoverability URL; the routing itself is `manifests/30-httproute.yaml`,
an `HTTPRoute` that attaches to the cube's gateway (`${GATEWAY_PACK}`) and
sends `workflows.${GATEWAY_FQDN}` to the `argo-server` Service on port `2746`.
Every schema-defaulted field is written out explicitly (the argocd SSA-diff
rule — see `packs/gitea/manifests/20-httproute.yaml`).

`argo-server` is run with **`--auth-mode=server`** (the single edit applied to
the vendored install — see below) so the local IDP reaches the server without
per-client Kubernetes bearer tokens. There is no bootstrap admin Secret, so the
`expose` block declares no `authSecretRef`/`impliedFields`.

## Namespaces — vendored verbatim, no transformer needed

Like argo-events (and unlike argo-rollouts, which needs a kustomize namespace
transformer because its upstream omits per-object namespaces), argo-workflows
upstream **already stamps** `metadata.namespace: argo` on every namespaced
object (both ServiceAccounts, the `argo-role` Role + its RoleBinding, the
`workflow-controller-configmap` ConfigMap, the `argo-server` Service, and both
Deployments) and on both ClusterRoleBinding subjects. cube-idp's delivery path
(rendered objects → OCI artifact → Flux `Kustomization` with no
`targetNamespace`) therefore applies them straight into `argo`. Cluster-scoped
objects (8 CRDs, 5 ClusterRoles, the `workflow-controller` PriorityClass)
correctly carry no namespace. `imagePullPolicy` is left verbatim (nothing
stripped or flipped).

## The one edit — `--auth-mode=server`

The A7 pack requires the Argo Server to run with `--auth-mode=server` for local
IDP use. Upstream `install.yaml` v4.0.7 sets the `argo-server` container args to
just `["server"]`, so the server would default to `--auth-mode=client` (for
Argo Workflows v3.0+ the default auth-mode is `client`; prior to v3.0 it was
`server`). Exactly one line — `        - --auth-mode=server` — is inserted into
the `argo-server` Deployment's args immediately after `        - server`.
Nothing else is changed from the pristine upstream file. The change is
documented in `manifests/20-install.yaml`'s header.

## Layout

- `manifests/10-namespace.yaml` — the vendored upstream file does not ship a
  `Namespace` object, so it is added here (namespace-first, copying argocd's
  layout).
- `manifests/20-install.yaml` — the vendored `install.yaml`. Byte-identical to
  the pristine upstream below its provenance header **except** the single
  `--auth-mode=server` line described above. Do not edit by hand; re-vendor per
  "Re-vendoring".
- `manifests/30-httproute.yaml` — the `HTTPRoute` exposing `argo-server` at
  `workflows.${GATEWAY_FQDN}`.

## Re-vendoring (version bumps)

`20-install.yaml` is the pristine upstream `install.yaml` plus one auth-mode
line. To bump the pinned version, refetch the upstream asset, re-prepend the
header block, and re-apply the single edit (the browser-download path may 302 to
an error page under load; the API asset endpoint is reliable):

```bash
VERSION=v4.0.7   # <- new pin
WORK=$(mktemp -d)
AID=$(gh api repos/argoproj/argo-workflows/releases/tags/${VERSION} \
  --jq '.assets[] | select(.name=="install.yaml") | .id')
gh api -H "Accept: application/octet-stream" \
  repos/argoproj/argo-workflows/releases/assets/${AID} > "$WORK/install.yaml"
sha256sum "$WORK/install.yaml"   # record in the header + FINDINGS
# Re-apply the single auth-mode edit (after "- server" in the argo-server args):
awk '/^        - server$/{print; print "        - --auth-mode=server"; next} {print}' \
  "$WORK/install.yaml" > "$WORK/install-edited.yaml"
# Re-prepend the existing header comment block over the edited bytes:
{ sed -n '/^#/p;/^[^#]/q' packs/argo-workflows/manifests/20-install.yaml; \
  cat "$WORK/install-edited.yaml"; } > packs/argo-workflows/manifests/20-install.yaml
```

Then update the version + sha256 references in this README and in the header,
and re-run conformance
(`bash hack/conformance.sh argo-workflows <cube-idp-binary>`).

## Verification method

No chart involved, so "verify against helm show values" doesn't apply here;
instead the vendored manifest was inspected directly: confirmed both images are
`quay.io/argoproj/{workflow-controller,argocli}:v4.0.7`, that the upstream file
ships no `Namespace` object, that every namespaced object and both
ClusterRoleBinding subjects already carry `namespace: argo`, that no
cluster-scoped object has a namespace, that both required Deployments
(`workflow-controller`, `argo-server`) are present, and that the argo-server
args carry `--auth-mode=server` (the one applied edit).

- `install.yaml`
  - URL: `https://github.com/argoproj/argo-workflows/releases/download/v4.0.7/install.yaml`
  - Version: `v4.0.7`
  - sha256 (pristine upstream, before the one auth-mode edit): `4e7112cd10dbb5a03c33653cda7509bdb8e876dcc64cf050c4c387aa07bf8524`
