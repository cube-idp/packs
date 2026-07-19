name:        "argo-rollouts"
version:     "0.1.0"
description: "progressive delivery controller (canary & blue-green) for Kubernetes"

// Manifests-kind pack: the upstream argo-rollouts release install.yaml
// installs the controller's own CRDs (Rollout, AnalysisRun, Experiment, …),
// RBAC, and the argo-rollouts controller Deployment in one shot, so there is
// no chart and no helm values. See manifests/20-install.yaml for the pinned
// upstream URL + version + sha256. Expose: none (the controller has no
// user-facing gateway surface — it reconciles Rollout CRs the user creates;
// the optional argo-rollouts dashboard ships separately and is not vendored).
