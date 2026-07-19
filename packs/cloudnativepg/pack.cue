name:        "cloudnativepg"
version:     "0.1.0"
description: "PostgreSQL operator for Kubernetes"

// Manifests-kind pack: the upstream CloudNativePG release manifest installs
// the operator's own CRDs and controller in one shot, so there is no chart
// and no helm values. See manifests/10-cnpg.yaml for the pinned upstream
// URL + version + sha256. Expose: none (the operator has no user-facing
// gateway surface — it reconciles Cluster CRs the user creates).
