#!/usr/bin/env bash
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
status=0

fail() {
  printf '[FAIL] %s\n' "$*" >&2
  status=1
}

for forbidden in \
  auth.json history.jsonl session_index.jsonl installation_id \
  '*.sqlite' '*.sqlite-shm' '*.sqlite-wal' '.zsh_history' '.bash_history' \
  'id_rsa' 'id_ed25519' '*.kdbx'; do
  while IFS= read -r path; do
    fail "forbidden file pattern $forbidden: ${path#"$root"/}"
  done < <(find "$root" -type f -name "$forbidden" -print)
done

while IFS= read -r path; do
  target="$(readlink -- "$path")"
  [[ "$target" == /* ]] && fail "absolute symlink: ${path#"$root"/} -> $target"
done < <(find "$root" -type l -print)

scan_roots=("$root/config" "$root/codex" "$root/bin" "$root/home" "$root/packages")
[[ -f "$root/profile.env" ]] && scan_roots+=("$root/profile.env")
if command -v rg >/dev/null; then
  if rg -n -i \
    '(/home/(chromatischer|god|alarm)(/|$)|BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE|api[_-]?key[[:space:]]*=|access[_-]?token[[:space:]]*=|client[_-]?secret[[:space:]]*=|sk-[A-Za-z0-9_-]{16,})' \
    "${scan_roots[@]}"; then
    fail 'personal path or secret-like value found in transferable payload'
  fi
else
  printf '[WARN] rg is unavailable; content scan skipped.\n' >&2
fi

if ((status)); then
  exit "$status"
fi
printf '[OK] No forbidden state, absolute links, source-user paths, or obvious secrets found.\n'
