#!/usr/bin/env bash
# Proteção de branch como código, versionada e auditável.
# Uso: ./apply-branch-protection.sh <org>/<repo>

set -euo pipefail
REPO="${1:?Uso: ./apply-branch-protection.sh <org>/<repo>}"

gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/${REPO}/branches/main/protection" \
  -f required_status_checks.strict=true \
  -f 'required_status_checks.contexts[]=secrets-scan' \
  -f 'required_status_checks.contexts[]=sast' \
  -f 'required_status_checks.contexts[]=sca-sbom' \
  -f 'required_status_checks.contexts[]=iac-scan' \
  -F required_pull_request_reviews.required_approving_review_count=2 \
  -f required_pull_request_reviews.require_code_owner_reviews=true \
  -f required_pull_request_reviews.dismiss_stale_reviews=true \
  -F enforce_admins=true \
  -f required_linear_history=true \
  -f allow_force_pushes=false \
  -f allow_deletions=false \
  -f required_signatures=true

echo "Branch protection aplicada em ${REPO}:main"
