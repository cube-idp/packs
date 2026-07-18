name:        "crossplane"
version:     "0.1.0"
description: "control plane framework for platform APIs"
#Values: {
	// top-level "replicas" is the crossplane chart's real values key for the
	// core pod (verified against crossplane 2.3.3's values.yaml; the chart
	// ships no values.schema.json). The RBAC manager's replica knob is the
	// separate "rbacManager.replicas" — not schematized here.
	replicas: int & >0 | *1
}
