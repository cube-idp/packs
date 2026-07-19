name:        "floci"
version:     "0.1.0"
description: "AWS-compatible local cloud emulator — S3, DynamoDB, SQS and other core services on a single endpoint"

// Authored-manifests pack. The floci upstream (github.com/floci-io/floci) is a
// Docker-only distribution — it ships no Kubernetes YAML — so the manifests in
// manifests/ are authored here, not vendored: a namespace, a single Deployment
// running the pinned emulator image, and a Service. See
// manifests/20-floci.yaml for the pinned image tag AND sha256 digest.
//
// IN-CLUSTER LIMITATION: floci's core services (S3, DynamoDB, SQS, SNS, …) run
// entirely inside the emulator process and work in kind. Its container-backed
// services (Lambda, RDS, ECS, …) require a Docker socket to spawn helper
// containers; kind nodes run containerd with no Docker socket, and this pack
// deliberately mounts NONE, so those services are unavailable here. See README.
//
// Expose (A10 row, A7 pattern): the emulator endpoint (port 4566) is exposed at
// https://floci.${GATEWAY_HOST}. The expose block below is the D11
// discoverability record; the actual routing is manifests/30-httproute.yaml,
// which points an HTTPRoute at the floci Service on port 4566. floci has no
// bootstrap admin Secret (it accepts any/dummy AWS credentials), so no
// authSecretRef/impliedFields are declared.
expose: {
	urls: ["https://floci.${GATEWAY_HOST}"]
}
