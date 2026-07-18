# floci starter pack

floci — an AWS-compatible local cloud emulator (an open-source alternative to
LocalStack Community). It exposes a single AWS-style endpoint on port `4566`;
point any AWS SDK or the `aws` CLI at it (`--endpoint-url`) with dummy
credentials and region `us-east-1` to exercise S3, DynamoDB, SQS, SNS, KMS,
Secrets Manager and the other core services against a local, always-free
emulator instead of a real AWS account.

The emulator endpoint is exposed at `https://floci.${GATEWAY_HOST}`.

## ⚠ In-cluster limitation — no Docker socket, so no container-backed services

**This is the most important thing to know about running floci in a cube.**

floci's **core services run entirely inside the emulator process** (a Quarkus
native binary) and work perfectly in-cluster: **S3, DynamoDB, SQS, SNS, KMS,
Secrets Manager, SSM, STS, IAM, CloudWatch/Logs, Kinesis, API Gateway,
Step Functions, EventBridge** and more.

floci's **container-backed services — Lambda, RDS, ECS, EKS, and any service
that spawns helper containers — require access to a Docker socket** so the
emulator can start those containers. **kind nodes run `containerd`, not Docker,
and expose no Docker socket**, and this pack **deliberately mounts none** (a
host Docker socket would be both unsafe and, on kind, absent). As a result
**those container-backed services are unavailable when floci runs inside a
cube.** The emulator still reports its full service catalog as "running" on
`/health`, but invoking a Lambda function or provisioning an RDS instance will
fail for lack of a container runtime. If you need those, run floci directly
under Docker on your workstation instead of in-cluster.

## Authored manifests — Docker-only upstream

floci is distributed **Docker-only** (`github.com/floci-io/floci`); the upstream
ships **no Kubernetes YAML**. This pack therefore **authors** the minimal set of
objects needed to run it in a cube — a `Namespace`, one `Deployment`, and one
`Service` — rather than vendoring an upstream manifest. There is no chart and no
helm values.

- `manifests/10-namespace.yaml` — the `floci` namespace (namespace-first,
  copying argocd's layout).
- `manifests/20-floci.yaml` — the authored `Deployment` (the pinned emulator
  image, resource requests/limits, and `/health`-backed readiness + liveness
  probes) and the `floci` `Service` exposing port `4566`.
- `manifests/30-httproute.yaml` — the `HTTPRoute` exposing the emulator at
  `floci.${GATEWAY_FQDN}`.

## Image pin

The Deployment pins the emulator image by **tag AND digest**:

- Image: `floci/floci:1.5.33`
- Digest (multi-arch index):
  `sha256:d2ecc8035822b23b8587a56eab15edd825f41d3fb80d93e8e66680410beddc08`
- Registry: `docker.io/floci/floci` (Docker Hub)

Verified at authoring (2026-07-19): `floci/floci:1.5.33` and `floci/floci:latest`
resolve to the **same** index digest above, so `1.5.33` is the latest stable
release. Pinning by digest as well as tag makes the pack reproducible even if
the `1.5.33` tag is ever re-pushed.

## Health gate

The engine reports the pack Ready once the `floci` Deployment in the `floci`
namespace is Available. `cube-idp status --exit-status` is green only then. The
container's readiness/liveness probes hit `GET /health` on port `4566`, which
the emulator answers `200` with a JSON services map (verified against the
running image) once it is up.

## Expose — the emulator endpoint

`pack.cue`'s `expose` block records `https://floci.${GATEWAY_HOST}` as the D11
discoverability URL; the routing itself is `manifests/30-httproute.yaml`, an
`HTTPRoute` that attaches to the cube's gateway (`${GATEWAY_PACK}`) and sends
`floci.${GATEWAY_FQDN}` to the `floci` Service on port `4566`. Every
schema-defaulted field is written out explicitly (the argocd SSA-diff rule — see
`packs/gitea/manifests/20-httproute.yaml`). floci accepts any/dummy AWS
credentials, so there is no bootstrap admin Secret and the `expose` block
declares no `authSecretRef`/`impliedFields`.

## Using it

Point an AWS SDK or the `aws` CLI at the exposed endpoint (dummy credentials,
`us-east-1`):

```bash
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1
aws --endpoint-url https://floci.${GATEWAY_HOST} s3 mb s3://demo
aws --endpoint-url https://floci.${GATEWAY_HOST} s3 ls
```

(Remember: S3/DynamoDB/SQS/… work; Lambda/RDS/ECS/EKS do not, per the limitation
above.)

## Re-pinning (version bumps)

To bump the pinned version, resolve the new tag's multi-arch index digest and
update both the tag and the digest in `manifests/20-floci.yaml` (and this
README):

```bash
VERSION=1.5.33   # <- new pin
docker buildx imagetools inspect floci/floci:${VERSION}   # read the top "Digest:" (the index digest)
# Confirm it is the latest stable by comparing with :latest:
docker buildx imagetools inspect floci/floci:latest       # same index digest => VERSION is latest
```

Then re-run conformance (`bash hack/conformance.sh floci <cube-idp-binary>`).

## Verification method

No chart involved, so "verify against helm show values" does not apply. Instead
the pinned image was inspected and run directly:

- `docker buildx imagetools inspect floci/floci:1.5.33` → multi-arch OCI index,
  index digest
  `sha256:d2ecc8035822b23b8587a56eab15edd825f41d3fb80d93e8e66680410beddc08`;
  the same digest as `:latest`, so `1.5.33` is the latest stable.
- Running the image confirmed it listens on `0.0.0.0:4566` (the only exposed
  port), logs `AWS Local Emulator 1.5.33 Ready`, detects the container context,
  and answers `GET /health` → `200` with a JSON services map. `POST /health`
  returns `405`; every other path falls through to the S3 service — so `/health`
  is the correct, unambiguous probe path.
