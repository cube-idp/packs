name:        "argo-workflows"
version:     "0.1.0"
description: "container-native workflow engine for Kubernetes — orchestrate parallel jobs as DAGs/steps"

// Manifests-kind pack: the upstream argo-workflows release install.yaml (the
// cluster-install variant) installs the operator's own CRDs, RBAC, the
// workflow-controller Deployment, and the argo-server Deployment + Service,
// all namespaced into "argo". There is no chart and no helm values.
// See manifests/20-install.yaml for the pinned upstream URL + version + sha256.
//
// Expose (A7 row): the argo-server UI/API is exposed at
// https://workflows.${GATEWAY_HOST}. The expose block below is the D11
// discoverability record; the actual routing is manifests/30-httproute.yaml,
// which points an HTTPRoute at the argo-server Service. argo-server is run with
// --auth-mode=server (see 20-install.yaml header) so the local IDP reaches it
// without per-client Kubernetes bearer tokens. argo-server has no bootstrap
// admin Secret, so no authSecretRef/impliedFields are declared.
expose: {
	urls: ["https://workflows.${GATEWAY_HOST}"]
}
