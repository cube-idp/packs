# floci-ui starter pack

floci-ui — the web console for the [floci](../floci) local cloud emulator. It is
a browser UI that talks to floci's AWS-compatible endpoint so you can browse and
poke at S3 buckets, DynamoDB tables, SQS queues and the other core services
without leaving the browser. The console is exposed at
`https://floci-ui.${GATEWAY_HOST}`.

## Requires the floci pack

floci-ui is a **console for floci** — it is useless on its own. Install the
[`floci`](../floci) pack (A10) alongside it; floci-ui reaches the emulator over
the in-cluster Service DNS `floci.floci.svc.cluster.local:4566` (env
`FLOCI_ENDPOINT`, set on the Deployment). floci-ui also **shares the `floci`
namespace** with the floci pack: the floci pack owns and creates that namespace
(`packs/floci/manifests/10-namespace.yaml`), so **this pack ships no Namespace
object** and stamps `metadata.namespace: floci` on its Deployment, Service and
HTTPRoute.

The same in-cluster limitation applies as for floci itself: core services
(S3, DynamoDB, SQS, …) work; container-backed services (Lambda, RDS, ECS, …) are
unavailable on kind (no Docker socket). See the floci pack's README for detail.

## Authored manifests — Docker-only upstream

floci-ui is distributed **Docker-only** (`github.com/floci-io/floci-ui`); the
upstream ships **no Kubernetes YAML**. This pack therefore **authors** the
minimal set of objects needed to run it in a cube — one `Deployment` and one
`Service` — rather than vendoring an upstream manifest. There is no chart and no
helm values.

- `manifests/20-floci-ui.yaml` — the authored `Deployment` (the pinned console
  image, `FLOCI_ENDPOINT` pointing at the floci Service, resource
  requests/limits, and `/`-backed readiness + liveness probes) and the
  `floci-ui` `Service` exposing port `4500`.
- `manifests/30-httproute.yaml` — the `HTTPRoute` exposing the console at
  `floci-ui.${GATEWAY_FQDN}`.

(There is no `10-namespace.yaml` — the namespace comes from the floci pack.)

## Image pin

The Deployment pins the console image by **tag AND digest**:

- Image: `floci/floci-ui:0.2.0`
- Digest (multi-arch index):
  `sha256:03a261144e0708993c8e48b763a0edb072415feae4325f254beeb1835fa424d9`
- Registry: `docker.io/floci/floci-ui` (Docker Hub)

Verified at authoring (2026-07-19): `floci/floci-ui:0.2.0` and
`floci/floci-ui:latest` resolve to the **same** index digest above, so `0.2.0`
is the latest stable release. Pinning by digest as well as tag makes the pack
reproducible even if the `0.2.0` tag is ever re-pushed.

## Ports — one port, 4500 (not 4500 + 4501)

**Verified by running the image.** The image config sets `PORT=4500` and the
container listens on a **single** port, `4500`; the UI and its API are served
together on that one port. The floci-ui server's *code* falls back to `4501`
only when `PORT` is unset, but the image sets `PORT=4500`, so **nothing ever
listens on 4501** — there is no separate API port. This pack therefore exposes
`4500` only, and sets `PORT=4500` explicitly on the Deployment so the listen
port can never drift from the code default.

## Health gate

The engine reports the pack Ready once the `floci-ui` Deployment in the `floci`
namespace is Available. `cube-idp status --exit-status` is green only then. The
container's readiness/liveness probes hit `GET /` on port `4500` (which serves
`index.html` with `200`) — verified by running the image, the console exposes
**no dedicated `/health` path** (every `/health`, `/healthz`, `/readyz`, … is
`404`), so `GET /` is the correct readiness signal.

## Expose — the console UI

`pack.cue`'s `expose` block records `https://floci-ui.${GATEWAY_HOST}` as the
D11 discoverability URL; the routing itself is `manifests/30-httproute.yaml`, an
`HTTPRoute` that attaches to the cube's gateway (`${GATEWAY_PACK}`) and sends
`floci-ui.${GATEWAY_FQDN}` to the `floci-ui` Service on port `4500`. Every
schema-defaulted field is written out explicitly (the argocd SSA-diff rule).
floci-ui authenticates to the emulator with the same any/dummy AWS credentials
floci accepts, so there is no bootstrap admin Secret and the `expose` block
declares no `authSecretRef`/`impliedFields`.

## Service links disabled

The Deployment sets `enableServiceLinks: false` (the same fix the floci pack
needed). In the shared `floci` namespace Kubernetes would otherwise inject
legacy Docker-style service-link env vars — `FLOCI_PORT` (from floci's Service)
and `FLOCI_UI_PORT` (from this pack's own Service) — of the form
`tcp://<clusterIP>:<port>`. Because the floci-ui server reads a whole family of
`FLOCI_*` env vars, an injected `FLOCI_*=tcp://…` value is exactly the class of
collision that CrashLoopBackOff'd the floci pod; disabling service links removes
that surface, and the app then reads only the env explicitly set on the
Deployment.

## Re-pinning (version bumps)

To bump the pinned version, resolve the new tag's multi-arch index digest and
update both the tag and the digest in `manifests/20-floci-ui.yaml` (and this
README):

```bash
VERSION=0.2.0   # <- new pin
docker buildx imagetools inspect floci/floci-ui:${VERSION}   # read the top "Digest:" (the index digest)
# Confirm it is the latest stable by comparing with :latest:
docker buildx imagetools inspect floci/floci-ui:latest       # same index digest => VERSION is latest
```

Then re-run conformance (floci-ui needs the floci pack present):

```bash
CUBE_IDP_CONFORMANCE_EXTRA_PACK_DIR=oci://ghcr.io/cube-idp/packs/floci:0.1.0 \
  bash hack/conformance.sh floci-ui <cube-idp-binary>
```

## Verification method

No chart involved, so "verify against helm show values" does not apply. Instead
the pinned image was inspected and run directly:

- `docker buildx imagetools inspect floci/floci-ui:0.2.0` → multi-arch OCI
  index, index digest
  `sha256:03a261144e0708993c8e48b763a0edb072415feae4325f254beeb1835fa424d9`; the
  same digest as `:latest`, so `0.2.0` is the latest stable.
- Running the image confirmed it listens on `0.0.0.0:4500` only, logs
  `Started development server: http://localhost:4500`, and serves `GET /` →
  `200` (`index.html`); no `/health`-style path exists (all `404`).
- Inspecting the server binary confirmed it reads `process.env.FLOCI_ENDPOINT`
  (default `http://localhost:4566`) to reach the floci emulator and
  `process.env.PORT` (image-set to `4500`) for its listen port.
