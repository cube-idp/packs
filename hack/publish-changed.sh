#!/usr/bin/env bash
# Publish every pack whose <name>/vX.Y.Z tag matches this git ref, then
# rebuild and push the index. Requires: cube-idp on PATH, ghcr login.
set -euo pipefail
REF="${GITHUB_REF_NAME:?set GITHUB_REF_NAME (e.g. gitea/v0.2.0)}"
NAME="${REF%%/v*}"; VERSION="${REF##*/v}"
test -d "packs/$NAME" || { echo "no such pack: $NAME"; exit 1; }
DIGEST=$(cube-idp pack publish "packs/$NAME" --ref "oci://ghcr.io/cube-idp/packs/$NAME:$VERSION" | grep -o 'sha256:[a-f0-9]*')
echo "published $NAME:$VERSION @ $DIGEST"
echo "$NAME=$DIGEST" >> digests.env
