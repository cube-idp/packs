name:        "argo-events"
version:     "0.1.0"
description: "event-driven autonomy for Kubernetes — event sources, buses, and sensors"

// Manifests-kind pack: the upstream argo-events release install.yaml installs
// the operator's own CRDs (EventBus, EventSource, Sensor), RBAC, the
// controller-manager Deployment, and its config, all namespaced into
// argo-events. The events-webhook Deployment + Service + RBAC ship in a
// SEPARATE upstream file (install-validating-webhook.yaml); both are vendored
// here because the A6 health gate requires controller-manager AND
// events-webhook Available. There is no chart and no helm values.
// See manifests/20-install.yaml and manifests/30-webhook.yaml for the pinned
// upstream URLs + version + sha256. Expose: none (argo-events has no
// user-facing gateway surface — it reconciles EventSource/Sensor/EventBus CRs
// the user creates).
