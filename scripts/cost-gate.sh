#!/usr/bin/env bash
# Usage: cost-gate.sh <infracost-diff.json> [max_increase_usd]
# Env:   COST_APPROVED=true  -> report but do not block (label override)
set -euo pipefail

DIFF_JSON="${1:?usage: cost-gate.sh <diff.json> [max_increase_usd]}"
MAX="${2:-50}"
APPROVED="${COST_APPROVED:-false}"

past=$(jq -r '.pastTotalMonthlyCost // "0"' "$DIFF_JSON")
new=$(jq -r '.totalMonthlyCost // "0"' "$DIFF_JSON")
delta=$(jq -r '.diffTotalMonthlyCost // "0"' "$DIFF_JSON")
unsupported=$(jq -r '.summary.totalUnsupportedResources // 0' "$DIFF_JSON")

printf "Current : \$%.2f / month\n" "$past"
printf "Proposed: \$%.2f / month\n" "$new"
printf "Increase: \$%.2f / month (limit \$%s)\n" "$delta" "$MAX"

if [ "$unsupported" != "0" ]; then
  echo "⚠️  $unsupported resource(s) could not be priced; estimate may be incomplete."
fi

if awk -v d="$delta" -v m="$MAX" 'BEGIN { exit !(d > m) }'; then
  if [ "$APPROVED" = "true" ]; then
    echo "⚠️  Threshold exceeded but PR has the 'cost-approved' label. Allowing."
    exit 0
  fi
  echo "❌ Cost increase exceeds threshold. Blocking."
  echo "   Reduce the change, or have a reviewer add the 'cost-approved' label."
  exit 1
fi

echo "✅ Within budget."
