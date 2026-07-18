# cube-idp packs

Data-only platform packs for [cube-idp](https://github.com/cube-idp/cube-idp),
published as OCI artifacts with GitHub-native provenance attestations. This is
the monorepo behind `oci://ghcr.io/cube-idp/packs/<name>` — the refs a default
`cube-idp init` writes into `cube.yaml`.

- **One directory per pack** under [`packs/`](packs/): `packs/<name>/` holds
  `pack.cue` plus `manifests/`, `kustomization.yaml`, and/or `chart.yaml`.
- **The pack format is a frozen public API** — [`CONTRACT.md`](CONTRACT.md)
  (contract v1). The normative copy lives in the cube-idp main repo at
  `docs/pack-contract-v1.md`; the file here is a verbatim copy of it.
- **Releases are per-pack git tags**: `<name>/vX.Y.Z` publishes
  `oci://ghcr.io/cube-idp/packs/<name>:X.Y.Z` and rebuilds the catalog index
  artifact `oci://ghcr.io/cube-idp/packs/index:latest`.
- **No signing keys anywhere**: provenance is keyless GitHub artifact
  attestation per published digest; verify with
  `gh attestation verify oci://ghcr.io/cube-idp/packs/<name>:<version> --owner cube-idp`.

## Adding a pack

1. Create `packs/<name>/` satisfying contract v1 ([`CONTRACT.md`](CONTRACT.md)):
   `pack.cue` with `name` (must equal the directory name), a semver
   `version`, and a one-line `description` (required for every pack in this
   repo — the catalog index publishes it), plus the pack's manifests, chart
   reference, or kustomization.
2. Prove it renders and comes up healthy: run the conformance harness
   against just your pack — `hack/conformance.sh <name>` (kind cluster +
   `cube-idp up` + health gate + teardown; the same gate CI runs per pack).
3. Open a PR. CI runs conformance; the pack contract's mechanical clauses
   are enforced by the same checks `cube-idp` itself ships.
4. Release by tagging: `git tag <name>/vX.Y.Z && git push origin <name>/vX.Y.Z`.
   The publish workflow validates that the tag version equals `pack.cue`'s
   `version`, pushes the artifact, attests its digest, and rebuilds the
   index.

## Repo layout

```text
packs/<name>/        one pack per directory (CONTRACT.md layout)
hack/                publish + conformance tooling used by CI and locally
.github/workflows/   publish.yml (tag-driven), conformance.yml (per-PR)
CONTRACT.md          pack contract v1 (verbatim copy; main repo is normative)
```

## Publishing pipeline

`hack/publish-changed.sh` reads the pushed tag (`<name>/vX.Y.Z`), publishes
that pack with `cube-idp pack publish`, and records `name=digest` lines in
`digests.env`. The workflow then rebuilds the full catalog index —
`cube-idp pack index build packs --from-registry --digest <just-published>`
— and pushes it with `cube-idp pack index push`. Identical content always
republishes to an identical digest, so re-running a tag's publish is a
no-op by construction.
