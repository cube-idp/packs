# prometheus-stack

The [kube-prometheus-stack][chart] Helm chart: the **Prometheus Operator**
plus **Prometheus**, **Alertmanager**, **Grafana**, **kube-state-metrics** and
**node-exporter** — a complete cluster-monitoring stack.

- **Kind:** helm (`chart.yaml`)
- **Namespace:** `monitoring`
- **Chart:** `kube-prometheus-stack` `87.17.0` (app `v0.92.1`) from
  `https://prometheus-community.github.io/helm-charts`
  — `kube-prometheus-stack-87.17.0.tgz`
  sha256 `e9d625daece8804bfa82959296e59cf146756d9aa638f207ebe20e01d6d75514`.
- **Release name:** `prometheus-stack` (pinned — the rendered object names
  depend on it; see below).
- **Expose:** `https://grafana.${GATEWAY_HOST}` → the `prometheus-stack-grafana`
  Service (port 80). Grafana login uses the bootstrap admin Secret
  `prometheus-stack-grafana` (namespace `monitoring`, keys `admin-user` /
  `admin-password`); the implied username is `admin`.

## Layout

- `chart.yaml` — the pinned chart ref plus `values:` that pin every image tag
  the chart would otherwise float (see below).
- `manifests/10-httproute.yaml` — an `HTTPRoute` attaching Grafana to the cube
  gateway (`${GATEWAY_PACK}`) at host `grafana.${GATEWAY_FQDN}`, backend the
  `prometheus-stack-grafana` Service on port 80. Every server-defaulted field is
  written out explicitly (argocd SSA-diff rule). The `monitoring` namespace is
  auto-prepended by cube-idp because the chart renders no `Namespace` object
  (CONTRACT §2).

## Health gate

The pack is Ready when:

- Deployment `prometheus-stack-grafana` is Available,
- the operator Deployment `prometheus-stack-kube-prom-operator` is Available,
- and the operator-created StatefulSet
  `prometheus-prometheus-stack-kube-prom-prometheus` is Ready.

The release name `prometheus-stack` is what makes those names resolve. The
Prometheus StatefulSet is created by the operator from the `Prometheus` CR
`prometheus-stack-kube-prom-prometheus` (so `sts` name =
`prometheus-` + CR name), a beat after the operator becomes Available.

## Pinned images

Every image the chart references is pinned to its chart-`87.17.0` default so
the render is self-evidently immutable. `helm template` with these values is
byte-identical to the chart-default render (only Grafana's randomly generated
admin password + its pod-checksum annotation differ between runs — chart
non-determinism, not a pin):

| Component | Image |
| --- | --- |
| grafana | `docker.io/grafana/grafana:13.1.0` |
| grafana config-sidecar | `quay.io/kiwigrid/k8s-sidecar:2.8.1` |
| prometheus-operator | `quay.io/prometheus-operator/prometheus-operator:v0.92.1` |
| prometheus-config-reloader | `quay.io/prometheus-operator/prometheus-config-reloader:v0.92.1` |
| prometheus | `quay.io/prometheus/prometheus:v3.13.1-distroless` |
| alertmanager | `quay.io/prometheus/alertmanager:v0.33.1` |
| kube-state-metrics | `registry.k8s.io/kube-state-metrics/kube-state-metrics:v2.19.1` |
| node-exporter | `quay.io/prometheus/node-exporter:v1.12.1-distroless` |
| admission-webhook certgen | `ghcr.io/jkroepke/kube-webhook-certgen:1.8.4` |
| thanos (default base image) | `quay.io/thanos/thanos:v0.42.0` |

## Values

No `#Values` schema is declared. This pack deliberately leaves user `values:`
unvalidated (CONTRACT §2: absent `#Values` → values pass through unvalidated)
so that any of the chart's very large, deeply-nested value surface can be set
by the user. A closed `#Values` would reject every non-schematized key
(CUBE-4002); schematizing the whole kube-prometheus-stack surface is
impractical, so it is omitted rather than made partial-and-closed.

## Re-vendoring

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
helm pull prometheus-community/kube-prometheus-stack --version 87.17.0
shasum -a 256 kube-prometheus-stack-87.17.0.tgz   # must match the sha256 above
```

Bump `version:` in `chart.yaml` deliberately, re-pin each image tag to the new
chart's defaults (`helm template … | grep image:`), re-verify the render is
identical to the chart default, and re-run conformance.

[chart]: https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
