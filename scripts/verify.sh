#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

bash -n "$root/install.sh" "$root"/bin/* "$root"/scripts/*.sh
"$root/scripts/privacy-check.sh"

if command -v shellcheck >/dev/null; then
  shellcheck "$root/install.sh" "$root"/bin/* "$root"/scripts/*.sh
else
  printf '[WARN] shellcheck is not installed; syntax and privacy checks still passed.\n'
fi

printf '[OK] Verification complete.\n'

