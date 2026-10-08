#!/usr/bin/env bash
# Keep one open "cranwatch alerts" issue in sync with _alerts/*.md (written by run.R):
#   alerts, no open issue  -> open one (the @mention emails you)
#   alerts, open issue     -> refresh the body; comment only with what's new
#   no alerts, open issue  -> close it
set -euo pipefail

label="cranwatch-alert"
gh label create "$label" --color D93F0B --description "Automated cranwatch alerts" 2>/dev/null || true
issue=$(gh issue list --label "$label" --state open --json number --jq '.[0].number // empty')

if [[ -s _alerts/active.md ]]; then
  if [[ -z "$issue" ]]; then
    gh issue create --title "cranwatch alerts" --label "$label" --body-file _alerts/active.md
  else
    gh issue edit "$issue" --body-file _alerts/active.md
    if [[ -s _alerts/new.md ]]; then
      gh issue comment "$issue" --body-file _alerts/new.md
    fi
  fi
elif [[ -n "$issue" ]]; then
  gh issue close "$issue" --comment "All clear: nothing flagged in the $(date -u +%F) run."
fi
