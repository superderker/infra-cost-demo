#!/usr/bin/env bash
# Run the same checks locally against a scenario, e.g.:
#   ./scripts/local-demo.sh              # baseline (terraform.tfvars)
#   ./scripts/local-demo.sh excessive
#   ./scripts/local-demo.sh reasonable
set -euo pipefail
cd "$(dirname "$0")/.."

VARFILE=()
if [ "${1:-}" != "" ]; then VARFILE=(--terraform-var-file "scenarios/$1.tfvars"); fi

# Baseline from terraform.tfvars, proposed from scenario
infracost breakdown --path . --format json --out-file /tmp/base.json --no-color >/dev/null
infracost diff --path . "${VARFILE[@]}" --compare-to /tmp/base.json \
  --format json --out-file /tmp/diff.json >/dev/null
infracost diff --path . "${VARFILE[@]}" --compare-to /tmp/base.json --no-color || true
./scripts/cost-gate.sh /tmp/diff.json "${MAX_INCREASE_USD:-50}"
