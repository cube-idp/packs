# kyverno-policies starter pack

Curated **Pod Security Standards — Baseline** policies for
[Kyverno](https://kyverno.io), shipped separately from the `kyverno` pack
so they stay optional. Every policy runs in **`validationFailureAction:
Audit`**: violations are reported (policy reports + admission warnings)
but never blocked, so you can adopt the baseline without breaking existing
workloads.

Authored from `kyverno/policies` pinned commit
`ef9843f08d25b3555fe69616f8612c9f915af5d4` (`pod-security/baseline`),
vendored verbatim except the one field noted under **Audit mode** below.

## Prerequisite

This pack ships **only** `ClusterPolicy` objects — it requires the
`kyverno` pack (its CRDs and admission/background controllers) to be
installed first. Order kyverno before kyverno-policies in your cube's
`packs:` list.

## What's installed

Eleven cluster-scoped `ClusterPolicy` objects, the canonical PSS baseline
set from the upstream `pod-security/baseline/kustomization.yaml`:

| Policy | Guards against |
| --- | --- |
| `disallow-capabilities` | adding capabilities beyond the allowed baseline set |
| `disallow-host-namespaces` | sharing the host PID / IPC / network namespaces |
| `disallow-host-path` | mounting `hostPath` volumes |
| `disallow-host-ports` | binding host ports |
| `disallow-host-process` | Windows host-process containers |
| `disallow-privileged-containers` | privileged mode |
| `disallow-proc-mount` | non-default `procMount` |
| `disallow-selinux` | custom SELinux `type` / `user` / `role` |
| `restrict-apparmor-profiles` | AppArmor profiles other than `runtime/default` / `localhost/*` |
| `restrict-seccomp` | seccomp profiles other than `RuntimeDefault` / `Localhost` |
| `restrict-sysctls` | sysctls outside the baseline-safe set |

The engine reports the pack Ready once Kyverno has admitted and reconciled
every `ClusterPolicy` (each reports a `Ready` condition once its rules
compile against the cluster). Installing the pack changes nothing about
what is *rejected* — in Audit mode it only surfaces violations.

## Audit mode

The A3 pack spec mandates the whole baseline set in `Audit`. Upstream
ships every baseline policy as `Audit` **except**
`restrict-apparmor-profiles`, which upstream sets to `Enforce`; that one
field is normalized to `Audit` here so the pack has a uniform,
non-blocking posture. To enforce instead, edit
`validationFailureAction: Enforce` on the policies you want to hard-block
(or fork the pack via Gitea delivery).

## Values

None. This pack has no `chart.yaml` and no `#Values` schema — setting
`values:` on it is a typed error (values are helm-only). Customize by
editing the `ClusterPolicy` manifests directly.
