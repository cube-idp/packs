# cube-engine-flux pack

The **flux GitOps engine**, packaged as a cube-idp chart pack
(engine-as-pack spec 2026-07-19, D1/D2). This is the pack `cube-idp up`
fetches, renders, and SSA-installs when `spec.engine.type: flux` — the
in-binary embedded flux manifests it replaces are retired.

This is an **engine pack**, not a workload pack: reference it via
`spec.engine.ref` (or let the published default resolve it), **not** via
`spec.packs`. Its render is install-only — the two flux controllers and
their CRDs/RBAC in the `flux-system` namespace, no HTTPRoute, no `expose`
block (spec D5: the engine is SSA'd before the gateway pack delivers the
Gateway API CRDs).

Renders:

- `chart.yaml` — the `fluxcd-community/flux2` helm chart (pinned
  `2.19.0`, app `v2.9.1`), with baked values that disable every controller
  cube-idp does not use, leaving only **source-controller** and
  **kustomize-controller** (parity with the retired
  `flux install --export --components=source-controller,kustomize-controller`
  blob). No `manifests/` dir — the chart carries the CRDs.

## Parity target and the community-chart caveat

The chart is `fluxcd-community/flux2` — a **community**-maintained chart,
**not** an `fluxcd/fluxcd` core artifact. Parity with the retired embedded
blob is the contract, and it is proven by the $ROOT e2e engine matrix
(`CUBE_IDP_E2E_ENGINE=flux`), not by the chart's provenance. Chart pin
`2.19.0` was chosen because its rendered controller images
(`source-controller:v1.9.2`, `kustomize-controller:v1.9.2`) match the
retired blob exactly — verified with `helm template`, not guessed.

## What's disabled and why

Baked in `chart.yaml` `values:` — the four unused controllers, each via
the chart's `<controller>.create: false` key (verified against
`helm show values fluxcd-community/flux2 --version 2.19.0`):

- `helmController.create: false`
- `notificationController.create: false`
- `imageAutomationController.create: false`
- `imageReflectionController.create: false`

A parity render (`helm template … --set <each>.create=false`) yields
**exactly two** Deployments — `source-controller` and
`kustomize-controller` — in `flux-system`.

## Tuning knob (resources, not replicas)

The flux2 chart models its controllers as **singletons**: the
`kustomizeController:` value block exposes **no replica key** (verified
against `helm show values … --version 2.19.0`). The operator-tunable knob
is therefore the controller's **resources**, not its replica count:

```yaml
spec:
  engine:
    type: flux
    values:
      kustomizeController:
        resources:
          requests:
            cpu: 250m   # default 100m
```

Verified: `--set kustomizeController.resources.requests.cpu=250m` lands in
the rendered `kustomize-controller` Deployment's container `resources`.
The $ROOT e2e (`TestEngineSelfManage`) drives this exact path and asserts
the rendered resources field converges — it reads this knob from here.

## Chart pin bump procedure

This pack **replaces** the retired `hack/gen-flux-manifests.sh` in $ROOT:
there is no manifest to regenerate. To move flux forward, bump the
`version:` in `chart.yaml` to a newer `fluxcd-community/flux2` chart
release (`helm search repo fluxcd-community/flux2 --versions`), confirm the
rendered `source-controller`/`kustomize-controller` image tags are the
flux distribution you intend, re-render to confirm exactly the two
controllers still land in `flux-system`, and let the $ROOT e2e engine
matrix prove parity. Bump deliberately, like `packs/traefik`.

## Open values (D3)

`pack.cue`'s `#Values: {...}` is an **open** struct: the operator controls
the full flux2 chart surface. Content validation is helm's, not CUE's —
unknown keys are silently ignored (the accepted operator-in-control cost).
Baked values above are merged under the operator's `spec.engine.values`.
