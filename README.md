# Cost-aware infrastructure changes with Infracost

Terraform (AWS, never deployed) + Infracost + GitHub Actions. A PR that raises the
estimated monthly cost by more than `MAX_INCREASE_USD` (default $250) fails the
`cost-check` job and cannot be merged.

Nothing is deployed and no AWS account is needed: the provider uses mock credentials
and Infracost prices resources from its own pricing API.

## One-time setup
1. Install: Terraform, Infracost (v2 CLI), jq. Then `infracost setup` (free login).
2. Push this repo to GitHub. **Commit this baseline to `main` first.**
3. CI auth: run `infracost ci setup --ci-pipeline` (Infracost v2 no longer uses
   `configure get api_key`). The GitHub workflow is added in the next step (WIP).
4. Repo -> Settings -> Branches -> rule for `main`: require a PR and require the
   status check `cost-check`.
5. Create a label named `cost-approved` (the override for intentional increases).

## Try it locally
    terraform init -backend=false && terraform plan   # valid, offline
    infracost scan                                    # baseline, ~ $8.55/mo
    ./scripts/local-demo.sh excessive                 # fails the gate
    ./scripts/local-demo.sh reasonable                # passes
    (cd app && docker compose up)                     # stand-in app on :8080

## Demo flow
1. `main`: show `main.tf`, `terraform plan`, and the Infracost breakdown.
2. Branch `excessive`: copy `scenarios/excessive.tfvars.example` over `terraform.tfvars`,
   open a PR. Plan passes, Infracost comment shows the jump, gate fails, merge blocked.
3. Push a commit copying `scenarios/reasonable.tfvars.example` over `terraform.tfvars`.
   Comment updates, gate passes.
4. Discuss limits: usage-based pricing, list prices vs bill,
   false positives (label override), unsupported resources, API outage (fails closed).

## Notes
- The gate script comes from the PR checkout, so a PR could edit it. In production,
  protect `scripts/` and `.github/` with CODEOWNERS.
- Check the Infracost docs for current action versions and flags.
