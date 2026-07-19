# kargo

[Kargo](https://kargo.io) is Akuity's multi-stage GitOps promotion engine — a
companion to Argo CD that models application promotion across environments
(stages) with freight, warehouses, and verification.

This is a **helm-kind** cube-idp pack sourced from an **OCI chart**.

## What it installs

- Chart: `kargo` **1.10.9** (app **v1.10.9**) from
  `oci://ghcr.io/akuity/kargo-charts/kargo`
  (chart tgz sha256 `d47241a3c827102eab525a5f804a0caa046766783ad3312be75e725d9acb7838`,
  OCI manifest digest `sha256:58c8e33c2eb63efc7195b6c8b5d92904859d7a63600b9d4b8b5e4d193d122767`).
- Release name `kargo`, namespace `kargo`.
- Deployments: `kargo-api`, `kargo-controller`,
  `kargo-webhooks-server`, `kargo-external-webhooks-server`,
  `kargo-management-controller`.
- Kargo's own CRDs (from the chart's `crds/` dir) and an HTTPRoute exposing the
  API/UI.

The **health gate** (A9 row) is: Deployments `kargo-api` **and**
`kargo-controller` Available. `cube-idp status --exit-status` goes green only
when those are Available.

## Requirement: cert-manager CRDs

Kargo's API server generates a self-signed TLS certificate by default
(`api.tls.selfSignedCert: true`), so the chart renders `Certificate` and
`Issuer` objects from the `cert-manager.io` API group. **cert-manager (its
CRDs) must be present in the cluster before kargo is delivered.** Install the
`cert-manager` pack alongside kargo, e.g.:

```yaml
spec:
  packs:
    - {ref: "oci://ghcr.io/cube-idp/packs/cert-manager:0.2.0"}
    - {ref: "oci://ghcr.io/cube-idp/packs/kargo:0.1.0"}
```

The conformance harness delivers cert-manager first via
`CUBE_IDP_CONFORMANCE_EXTRA_PACK_DIR`.

> **Known cross-pack ordering caveat (deferred $ROOT engine follow-up).**
> cube-idp delivers each pack as its own flux Kustomization with no
> `dependsOn`, so kargo's Kustomization can dry-run against a stale
> kustomize-controller RESTMapper that predates cert-manager's CRDs and fail
> `no matches for kind "Certificate"/"Issuer"` until the mapper refreshes
> (owner-accepted, same race as the kyverno-policies/A3 pack). Bouncing
> kustomize-controller (`kubectl rollout restart deploy/kustomize-controller
> -n flux-system`) clears it. This is an engine gap, not a pack defect.

## Admin account

The kargo chart **fails to render** unless an admin account is configured. This
pack ships **local-IDP default credentials** in `chart.yaml` `values:` so it
installs out of the box:

- Username: `admin` (kargo's implicit admin login)
- Password: `admin` (`api.adminAccount.passwordHash` is a bcrypt hash of it)
- `api.adminAccount.tokenSigningKey` is a fixed JWT signing key.

The chart writes these into a generated Secret named `kargo-api` (keys
`ADMIN_ACCOUNT_PASSWORD_HASH` / `ADMIN_ACCOUNT_TOKEN_SIGNING_KEY`) — that Secret
holds only the hash + signing key, never a readable password, which is why the
pack's `expose` block declares **no `authSecretRef`** (there is no retrievable
bootstrap credential to reference — same choice as the argo-workflows pack).

**Override for any non-local use.** Set your own values, e.g.:

```yaml
spec:
  packs:
    - ref: "oci://ghcr.io/cube-idp/packs/kargo:0.1.0"
      values:
        api:
          adminAccount:
            passwordHash: "<your bcrypt hash>"
            tokenSigningKey: "<your signing key>"
```

Generate a hash + key:

```sh
# bcrypt hash of your password (note the 2a prefix kargo expects):
htpasswd -bnBC 10 "" 'your-password' | tr -d ':\n' | sed 's/^\$2y/\$2a/'
# a token signing key:
openssl rand -base64 29 | tr -d "=+/" | cut -c1-40
```

## Expose

The API/UI is exposed at `https://kargo.${GATEWAY_HOST}` (D11 record in
`pack.cue`). Routing is `manifests/10-httproute.yaml`: an HTTPRoute attaching to
the cube gateway (`${GATEWAY_PACK}`), hostname `kargo.${GATEWAY_FQDN}`,
backendRef → Service `kargo-api` **port 443**. The API server serves HTTPS
behind its self-signed cert (`TLS_ENABLED=true`); the pack does not flip it to
plaintext.

## Values (`#Values` omitted)

This pack declares **no `#Values`** schema, so users may pass **any** of the
chart's values (CONTRACT §2: absent `#Values` → values pass through
unvalidated). Kargo's value surface is large and deeply nested; a partial
closed schema would reject legitimate chart values (the closedness pitfall the
kyverno/A2 pack documented), so omission keeps the full surface open — the same
choice the prometheus-stack/A8 pack made.

## Image pin

The chart floats a single image, `ghcr.io/akuity/kargo`, whose tag defaults to
the chart AppVersion. `values.image.tag` is pinned to `v1.10.9` (equal to the
AppVersion resolution) so the render is byte-identical to the chart default
while the tag can never float on a chart-default change.

## Re-vendoring

```sh
helm pull oci://ghcr.io/akuity/kargo-charts/kargo --version 1.10.9
shasum -a 256 kargo-1.10.9.tgz   # expect d47241a3...acb7838
# verify the pin is inert and the gate deployments render:
helm template kargo kargo-1.10.9.tgz --namespace kargo \
  --set image.tag=v1.10.9 \
  --set api.adminAccount.passwordHash='<hash>' \
  --set api.adminAccount.tokenSigningKey='<key>' \
  | grep -A2 '^kind: Deployment' | grep 'name: kargo-api\|name: kargo-controller'
```
