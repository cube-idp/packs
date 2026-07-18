name:        "kargo"
version:     "0.1.0"
description: "Kargo — multi-stage GitOps promotion engine (Argo CD companion) by Akuity"

// Helm-kind pack sourced from an OCI chart (chart.yaml carries the full
// oci:// ref in `chart:`; the pack renderer detects registry.IsOCI and pulls
// via the OCI registry client — no `repo:` field is used for OCI charts).
// releaseName "kargo" + namespace "kargo" make the rendered names satisfy the
// A9 health gate: Deployments kargo-api and kargo-controller Available.
//
// Kargo requires cert-manager CRDs: with api.tls.selfSignedCert defaulting
// true, the chart renders Certificate + Issuer objects (cert-manager.io) for
// the API server's self-signed TLS. The conformance run delivers the
// cert-manager pack before kargo (CUBE_IDP_CONFORMANCE_EXTRA_PACK_DIR).
//
// No #Values is declared, so users may pass ANY of the chart's values
// (CONTRACT §2: absent #Values → values pass through unvalidated). Kargo's
// value surface is large and deeply nested (api / controller / webhooks /
// oidc / dex / ...); a partial closed schema would reject legitimate chart
// values (A2's closedness finding, CUBE-4002), and A8 established omission as
// the clean way to keep the full surface open — see README + FINDINGS.
//
// Expose (A9 row): the Kargo API/UI is exposed at https://kargo.${GATEWAY_HOST}.
// This expose block is the D11 discoverability record; the actual routing is
// manifests/10-httproute.yaml, an HTTPRoute → Service kargo-api (port 443 —
// the API serves HTTPS behind its self-signed cert). NO authSecretRef: unlike
// grafana/argocd, kargo's generated `kargo-api` Secret stores only a bcrypt
// PASSWORD HASH (ADMIN_ACCOUNT_PASSWORD_HASH) plus a JWT signing key — never a
// readable bootstrap password — so there is no retrievable credential to
// reference (same rationale the argo-workflows/A7 pack used for omitting it).
// The admin login is documented in the README (admin account, chart-supplied
// credentials in chart.yaml values).
expose: {
	urls: ["https://kargo.${GATEWAY_HOST}"]
}
