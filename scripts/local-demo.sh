#!/usr/bin/env bash
# Simulate a PR locally: baseline = current terraform.tfvars, proposal = a scenario.
#   ./scripts/local-demo.sh excessive
#   ./scripts/local-demo.sh reasonable
# terraform.tfvars is restored afterwards.
set -euo pipefail
cd "$(dirname "$0")/.."

SCENARIO="${1:?usage: local-demo.sh <excessive|reasonable>}"
[ -f "scenarios/$SCENARIO.tfvars.example" ] || { echo "No such scenario: $SCENARIO"; exit 1; }

cp terraform.tfvars /tmp/terraform.tfvars.orig
trap 'cp /tmp/terraform.tfvars.orig terraform.tfvars' EXIT

echo "== Baseline =="
infracost scan --no-color >/dev/null
infracost inspect --json > /tmp/base.json

echo "== Proposed ($SCENARIO) =="
cp "scenarios/$SCENARIO.tfvars.example" terraform.tfvars
infracost scan --no-color >/dev/null
infracost inspect --json > /tmp/pr.json

echo
./scripts/cost-gate.sh /tmp/base.json /tmp/pr.json "${MAX_INCREASE_USD:-250}"
