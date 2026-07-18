name:        "floci-ui"
version:     "0.1.0"
description: "Web console for the floci local cloud emulator — browse S3, DynamoDB, SQS and other core services in a browser"

// Authored-manifests pack. The floci-ui upstream (github.com/floci-io/floci-ui,
// the floci web console) is a Docker-only distribution — it ships no Kubernetes
// YAML — so the manifests in manifests/ are authored here, not vendored: a
// single Deployment running the pinned console image and a Service. See
// manifests/20-floci-ui.yaml for the pinned image tag AND sha256 digest.
//
// SHARED NAMESPACE with the floci pack (A10): floci-ui runs in the `floci`
// namespace, which the floci pack already owns and creates
// (packs/floci/manifests/10-namespace.yaml). This pack therefore ships NO
// Namespace object; it stamps metadata.namespace: floci on its Deployment,
// Service and HTTPRoute. floci-ui reaches the emulator over the in-cluster
// Service DNS floci.floci.svc.cluster.local:4566 via env FLOCI_ENDPOINT.
//
// Expose (A11 row, A7 pattern): the console UI (port 4500) is exposed at
// https://floci-ui.${GATEWAY_HOST}. The expose block below is the D11
// discoverability record; the actual routing is manifests/30-httproute.yaml,
// which points an HTTPRoute at the floci-ui Service on port 4500. floci-ui has
// no bootstrap admin Secret (it authenticates to the emulator with the same
// any/dummy AWS credentials floci accepts), so no authSecretRef/impliedFields
// are declared.
expose: {
	urls: ["https://floci-ui.${GATEWAY_HOST}"]
}
