#!/usr/bin/env bash
# Usage: cost-gate.sh <base.json> <pr.json> [max_increase_usd]
# Inputs: `infracost inspect --json` output (v2 CLI, field .monthly_cost) or
# `infracost breakdown --format json` output (legacy CLI in CI, field .totalMonthlyCost).
# Env:   COST_APPROVED=true -> report the overrun but do not block (label override)
set -euo pipefail

BASE_JSON="${1:?usage: cost-gate.sh <base.json> <pr.json> [max_increase_usd]}"
PR_JSON="${2:?usage: cost-gate.sh <base.json> <pr.json> [max_increase_usd]}"
MAX="${3:-50}"
APPROVED="${COST_APPROVED:-false}"

# monthly_cost is a string like "8.5528"; fail closed if missing
past=$(jq -er '(.monthly_cost // .totalMonthlyCost) | tonumber' "$BASE_JSON") || { echo "❌ Could not read baseline cost"; exit 1; }
new=$(jq -er '(.monthly_cost // .totalMonthlyCost) | tonumber' "$PR_JSON")     || { echo "❌ Could not read proposed cost"; exit 1; }
errors=$(jq -r '(.critical_diagnostics // 0) + (.projects_with_errors // 0)' "$PR_JSON")

if [ "$errors" != "0" ]; then
  echo "❌ Scan reported errors; cost estimate is not trustworthy. Blocking."
  exit 1
fi

delta=$(awk -v a="$past" -v b="$new" 'BEGIN { printf "%.2f", b - a }')

printf "Current : \$%.2f / month\n" "$past"
printf "Proposed: \$%.2f / month\n" "$new"
printf "Increase: \$%s / month (limit \$%s)\n" "$delta" "$MAX"

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
