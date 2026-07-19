# cube-engine-flux pack

The **flux GitOps engine**, packaged as a cube-idp **vendored-manifests**
pack (engine-as-pack spec 2026-07-19, D1/D2 as narrowed by spec §10). This
is the pack `cube-idp up` fetches, renders, and SSA-installs when
`spec.engine.type: flux` — the in-binary embedded flux manifests it
replaces are retired.

This is an **engine pack**, not a workload pack: reference it via
`spec.engine.ref` (or let the published default resolve it), **not** via
`spec.packs`. Its render is install-only — the two flux controllers and
their CRDs/RBAC in the `flux-system` namespace, no HTTPRoute, no `expose`
block (spec D5: the engine is SSA'd before the gateway pack delivers the
Gateway API CRDs).

Renders:

- `manifests/install.yaml` — the vendored output of
  `flux install --export --components=source-controller,kustomize-controller`
  (flux controllers `v1.9.2`). Self-stamped `flux-system` namespaces,
  including the `Namespace` object. Only the two controllers cube-idp uses
  — **source-controller** and **kustomize-controller** — plus their CRDs
  and RBAC. No `chart.yaml`: this is a chartless, data-only pack.

## Why manifests, not a chart (namespace correctness)

The only flux helm chart in existence, `fluxcd-community/flux2`, renders
**zero** objects with `metadata.namespace` at every version — it is built
for `helm install --namespace X`, where helm defaults the namespace at
apply time against a live cluster's REST mapper. cube-idp renders
client-side and hermetically (`action.DryRunClient`), where that defaulting
never runs, and cube-idp's Applier hard-fails on namespaced objects that
carry no namespace. fluxcd ships no official install chart (manifests only,
via `flux install --export`). So the flux engine pack vendors those
manifests directly: they self-stamp `flux-system` on every namespaced
object and include the `Namespace` object, which is exactly what cube-idp
needs. (See spec §10 amendment for the full decision trail — a render-path
namespace stamp was considered and rejected by the owner.)

The vendored manifests are, by construction, byte-identical to the retired
$ROOT embed (`internal/engine/flux/manifests/install.yaml`), so parity with
the previous behaviour holds automatically. Parity is also proven by the
$ROOT e2e engine matrix (`CUBE_IDP_E2E_ENGINE=flux`).

## Customisation is not possible for the flux engine pack (this phase)

Unlike the argocd engine pack, the flux engine pack is **chartless**, so it
takes **no values**. Setting `spec.engine.values` with `type: flux` is a
typed error — **CUBE-4016** (GT15: values are helm-only; a data-only
manifests pack cannot consume them). There is intentionally no `#Values`
field in `pack.cue`.

Customisation of the flux engine arrives later, via the **self-managed
setup** (GT16) — `spec.engine.selfManage`, where flux reconciles its own
install and the operator can layer changes through that path. That is
owner-deferred and out of scope for this phase.

## Bump procedure

This pack **replaces** the retired `hack/gen-flux-manifests.sh` in $ROOT.
To move flux forward, regenerate `manifests/install.yaml` with the flux CLI
at the target version:

```bash
flux install --export \
  --components=source-controller,kustomize-controller \
  > manifests/install.yaml
```

Confirm the rendered controller image tags are the flux distribution you
intend, confirm exactly the two controllers still land in `flux-system`,
and let the $ROOT e2e engine matrix prove parity. Bump deliberately, like
`packs/traefik`.
