name:        "kyverno-policies"
version:     "0.1.0"
description: "Pod Security Standards baseline policies for kyverno (audit mode)"

// Cluster-scoped ClusterPolicies only — no namespace, no gateway exposure,
// no user values. Requires the kyverno pack (its CRDs + admission
// controller) to be installed first; on its own this pack renders 11
// ClusterPolicy objects in validationFailureAction: Audit. Authored from
// kyverno/policies @ ef9843f08d25b3555fe69616f8612c9f915af5d4
// (pod-security/baseline). See README.md for the pin and the exact set.
