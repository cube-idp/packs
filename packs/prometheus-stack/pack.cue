name:        "prometheus-stack"
version:     "0.1.0"
description: "Prometheus, Alertmanager, Grafana and the Prometheus Operator — cluster monitoring stack"

// Helm-kind pack: the kube-prometheus-stack chart (see chart.yaml) installs
// the Prometheus Operator plus Grafana, kube-state-metrics and node-exporter,
// and Prometheus/Alertmanager custom resources the operator turns into
// StatefulSets. releaseName "prometheus-stack" makes the rendered names match
// the health gate (deployment prometheus-stack-grafana, operator deployment
// prometheus-stack-kube-prom-operator, StatefulSet
// prometheus-prometheus-stack-kube-prom-prometheus). No #Values is declared so
// users may pass ANY of the chart's values (CONTRACT §2: absent #Values →
// values pass through unvalidated) — see README + FINDINGS for the rationale.
//
// Expose (A8 row): Grafana is exposed at https://grafana.${GATEWAY_HOST}. The
// expose block below is the D11 discoverability record; the actual routing is
// manifests/10-httproute.yaml, which points an HTTPRoute at the
// prometheus-stack-grafana Service (port 80). Grafana ships a bootstrap admin
// Secret (prometheus-stack-grafana in ns monitoring, keys admin-user /
// admin-password); the implicit login user is "admin", declared here rather
// than read from the secret (same shape as the argocd pack).
expose: {
	urls: ["https://grafana.${GATEWAY_HOST}"]
	authSecretRef: {namespace: "monitoring", name: "prometheus-stack-grafana"}
	impliedFields: {username: "admin"}
}
