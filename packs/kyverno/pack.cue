name:        "kyverno"
version:     "0.1.0"
description: "Kubernetes-native policy engine"
#Values: {
	// Per-controller replica knobs — the kyverno chart's real values keys
	// (verified against kyverno 3.8.2's values.yaml; the chart ships no
	// values.schema.json). The chart's own default is null (Kubernetes
	// defaults each Deployment to 1), so these are optional with no CUE
	// default: a vanilla install renders exactly the chart's defaults.
	// Kyverno documents 3 as the supported replica count for an HA
	// admission controller.
	admissionController?: replicas:  int & >0
	backgroundController?: replicas: int & >0
	cleanupController?: replicas:    int & >0
	reportsController?: replicas:    int & >0
	// Open schema: every other kyverno chart value (features, config,
	// cleanupJobs, …) passes through to the helm render unvalidated.
	...
}
