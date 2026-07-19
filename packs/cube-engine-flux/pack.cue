name:        "cube-engine-flux"
version:     "0.1.0"
description: "flux GitOps engine (cube-idp engine pack)"
// Chartless vendored-manifests pack per engine-as-pack spec §10: the flux2
// community chart renders no metadata.namespace on any object, so the pack
// vendors the `flux install --export` manifests instead (self-stamped
// flux-system namespaces). No #Values — engine.values with the flux engine
// is a typed CUBE-4016 error (GT15: values are helm-only).
