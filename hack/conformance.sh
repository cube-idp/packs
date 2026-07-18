#!/usr/bin/env bash
# Conformance: one pack, one throwaway kind cluster, hard health gate.
# Usage: conformance.sh <pack-name> [cube-idp-binary]
#
# Exit 0 = conformant. The pack under test is delivered from this repo's
# packs/<name> into a fresh kind cluster behind the traefik gateway;
# one-shot `cube-idp status` is the gate (exit 1 iff any component is
# unhealthy). Gateway packs (traefik, envoy-gateway) ARE the gateway under
# test: they render through the gateway template instead (no pack list,
# gateway.ref = the pack dir). The binary must be on PATH or absolute.
#
# The gateway defaults to the published oci ref below (P4). For offline
# runs, or before the published tag is live, override with
# CUBE_IDP_CONFORMANCE_GATEWAY_REF=<this-repo>/packs/traefik.
set -euo pipefail
PACK="${1:?usage: conformance.sh <pack-name>}"
BIN="${2:-cube-idp}"
PORT="${CUBE_IDP_E2E_GATEWAY_PORT:-18443}"
GATEWAY_REF="${CUBE_IDP_CONFORMANCE_GATEWAY_REF:-oci://ghcr.io/cube-idp/packs/traefik:0.2.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
test -d "$ROOT/packs/$PACK" || { echo "no such pack: $PACK"; exit 1; }
WORK="$(mktemp -d)"; trap 'cd /; "$BIN" down --yes -f "$WORK/cube.yaml" >/dev/null 2>&1 || true; rm -rf "$WORK"' EXIT
NAME="conf-${PACK//[^a-z0-9]/}"
case "$PACK" in
traefik|envoy-gateway)
  sed -e "s|{{NAME}}|$NAME|" -e "s|{{PORT}}|$PORT|" -e "s|{{PACK}}|$PACK|" \
    -e "s|{{PACK_DIR}}|$ROOT/packs/$PACK|" \
    "$ROOT/hack/conformance_config_gateway.tmpl.yaml" > "$WORK/cube.yaml"
  ;;
*)
  sed -e "s|{{NAME}}|$NAME|" -e "s|{{PORT}}|$PORT|" -e "s|{{GATEWAY_REF}}|$GATEWAY_REF|" \
    -e "s|{{PACK_DIR}}|$ROOT/packs/$PACK|" \
    "$ROOT/hack/conformance_config.tmpl.yaml" > "$WORK/cube.yaml"
  ;;
esac
cd "$WORK"
"$BIN" up -f cube.yaml
"$BIN" status -f cube.yaml --exit-status
echo "CONFORMANT: $PACK"
