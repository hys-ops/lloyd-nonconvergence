#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
root="$PWD"
bin="$(lake env which lean)"
packages="$(realpath .lake/packages)"
revision="$(git -C "$packages/mathlib" rev-parse HEAD)"
test "$revision" = d13f23b723b8a846827a245b89c10fc7d3f11612
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/new" "$tmp/deps" logs
# The only project module allowed outside the empty new-output directory is the
# byte-identical prior dependency. A fresh checkout compiles that dependency once.
IFS=: read -ra paths <<< "$(lake env printenv LEAN_PATH)"
export LEAN_PATH="$tmp/new:$tmp/deps"
for entry in "${paths[@]}"; do
  path="$(realpath -m "$entry")"
  if [[ "$path" == "$packages/"* ]]; then export LEAN_PATH="$LEAN_PATH:$path"; fi
done
sha256sum -c sources.sha256 > logs/source-check.log
if [[ -n "${PRIOR_MANYROWS_DIR:-}" ]]; then
  (cd "$PRIOR_MANYROWS_DIR" && sha256sum -c "$root/prior-artifact.sha256")
  cp "$PRIOR_MANYROWS_DIR/ManyRows.olean" "$tmp/deps/"
  prior='reused previously compiled ManyRows.olean after fingerprint comparison'
else
  "$bin" -DwarningAsError=true -o "$tmp/deps/ManyRows.olean" ManyRows.lean
  prior='compiled the unchanged archived ManyRows.lean dependency once'
fi
{
  "$bin" --version
  echo "mathlib $revision"
  echo "$prior"
  echo 'All new module outputs start in an empty directory'
  for m in ScalingCuts HalfSteps ScalingLimits EntropicPlan PlanCertificate Alternation RuntimeBounds GibbsStop DenseChecks CacheReuse CachedKernel PairedCertificate SummaryBridge SquaredGeometry CertifiedExit; do
    "$bin" -DwarningAsError=true -o "$tmp/new/$m.olean" "$m.lean"
    echo "PASS $m"
  done
  "$bin" -DwarningAsError=true Audit.lean > logs/axioms.log
  python3 audit_output.py
} | tee logs/clean-build.log
