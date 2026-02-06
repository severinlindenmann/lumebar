#!/usr/bin/env bash
set -euo pipefail

echo "[smoke] validating basic CLI availability"
if ! command -v lume >/dev/null 2>&1; then
  echo "[smoke] lume not found on runner; skipping CLI smoke checks"
  exit 0
fi

lume --version
lume ls --help >/dev/null
lume run --help >/dev/null
lume stop --help >/dev/null
echo "[smoke] non-destructive CLI checks passed"

if [[ "${LUMEBAR_RUN_MUTATING_SMOKE:-0}" == "1" ]]; then
  if [[ -z "${LUMEBAR_SMOKE_VM:-}" ]]; then
    echo "[smoke] LUMEBAR_RUN_MUTATING_SMOKE=1 requires LUMEBAR_SMOKE_VM to be set"
    exit 1
  fi

  echo "[smoke] running mutating smoke checks on VM: ${LUMEBAR_SMOKE_VM}"
  lume run "${LUMEBAR_SMOKE_VM}" --no-display
  sleep 2
  lume stop "${LUMEBAR_SMOKE_VM}"
  echo "[smoke] mutating smoke checks passed"
fi
