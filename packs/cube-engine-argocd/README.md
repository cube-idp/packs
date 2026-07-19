# cube-engine-argocd pack

The **Argo CD GitOps engine**, packaged as a cube-idp chart pack
(engine-as-pack spec 2026-07-19, D1/D2). This is the pack `cube-idp up`
fetches, renders, and SSA-installs when `spec.engine.type: argocd` — the
in-binary embedded argo-cd manifests it replaces are retired.

This is an **engine pack**, not a workload pack: reference it via
`spec.engine.ref` (or let the published default resolve it), **not** via
`spec.packs`. It is distinct from `packs/argocd` (the UI-oriented pack);
pointing the argocd engine at any other pack is a typed error
(CUBE-0013).

Renders:

- `chart.yaml` — the `argoproj/argo-helm` `argo-cd` helm chart (pinned
  `10.1.4`, app `v3.4.5`), with the baked values below. This is a
  **community** chart, **not** argoproj's core `install.yaml`; parity with
  the retired embedded blob is the contract, proven by the $ROOT e2e
  engine matrix (`CUBE_IDP_E2E_ENGINE=argocd`).
- `manifests/10-repo-secret.yaml` — the zot registry OCI repo-creds
  Secret (a core `v1/Secret` in namespace `argocd`, bootstrap-safe),
  copied verbatim from the retired `internal/engine/argocd/manifests/
  repo-secret.yaml`. It registers the in-cluster zot registry as an OCI
  repository credential template so every pack cube-idp delivers under the
  zot host is matched by URL prefix.

## Parity target and the community-chart caveat

The chart is `argoproj/argo-helm` (`argo-cd`) — a **community**-maintained
chart, **not** argoproj's core `install.yaml`. Chart pin `10.1.4` was
chosen because it is the newest chart version whose `APP VERSION` is
`v3.4.5` — the argo-cd version the retired embedded blob vendored (the
repo secret's field names are verified against argo-cd `v3.4.5` source).
Parity is proven by the $ROOT e2e engine matrix, not by the chart's
provenance.

## Baked values and why each exists

Baked in `chart.yaml` `values:` — every entry carries a retired
`install.yaml` hand-edit:

- `global.image.imagePullPolicy: IfNotPresent` — **airgap** guard: bundles
  node-load the engine images, and `Always` would bypass them and try to
  pull from the network.
- `configs.params."server.insecure": true` — argocd-server serves **HTTP**
  behind cube-idp's gateway; without it the self-signed TLS redirect loops.
- `configs.params."reposerver.oci.layer.media.types"` — **load-bearing for
  OCI pack delivery**: widens argocd-repo-server's OCI layer media-type
  allow-list so it accepts the flux-style artifact media types cube-idp
  pushes to zot. Pack delivery fails without it.

A render with these values applied yields **zero** `imagePullPolicy:
Always` occurrences and lands the media-types + `server.insecure` params in
`argocd-cmd-params-cm` (verified with `helm template`).

## No UI HTTPRoute here (spec D5)

The Argo CD UI's HTTPRoute deliberately does **not** live in this pack.
The engine is SSA'd on a fresh cluster *before* the gateway pack delivers
the Gateway API CRDs, so a gateway-dependent object here would fail the
bootstrap SSA dry-run. UI exposure is a deferred, opt-in follow-up (spec
§8.1) — a route-only pack in `spec.packs`, not an engine concern.

## Chart pin bump procedure

This pack **replaces** the retired `hack/gen-argocd-manifests.sh` and its
`inject-argocd-cmd-params.awk` injector in $ROOT: there is no manifest to
regenerate and no ConfigMap to hand-patch — the baked chart values carry
what the awk injector used to. To move Argo CD forward, bump the
`version:` in `chart.yaml` to a newer `argoproj/argo-helm` `argo-cd` chart
release (`helm search repo argo/argo-cd --versions`), confirm its `APP
VERSION` is the argo-cd version you intend, re-render to confirm the airgap
(`imagePullPolicy: Always` count 0) and OCI media-types guards still hold,
and let the $ROOT e2e engine matrix prove parity. Bump deliberately, like
`packs/traefik`.

## Open values (D3)

`pack.cue`'s `#Values: {...}` is an **open** struct: the operator controls
the full `argo-cd` chart surface. Content validation is helm's, not CUE's
— unknown keys are silently ignored (the accepted operator-in-control
cost). Baked values above are merged under the operator's
`spec.engine.values`.
