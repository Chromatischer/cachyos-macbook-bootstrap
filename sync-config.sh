#!/usr/bin/env bash
# Apply only portable, user-owned configuration. No package or system changes.
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
dry_run=0
[[ ${1:-} == --dry-run ]] && dry_run=1
[[ $# -le 1 ]] || { echo 'Usage: ./sync-config.sh [--dry-run]' >&2; exit 2; }

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
backup="${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-macbook-bootstrap/config-backups/$stamp"

backup_file() {
  local target=$1 relative
  if [[ -e "$target" || -L "$target" ]]; then
    relative="${target#/}"
    mkdir -p "$backup/$(dirname -- "$relative")"
    cp -a -- "$target" "$backup/$relative"
  fi
}

copy_file() {
  local source=$1 target=$2
  [[ -f "$source" ]] || return 0
  if ((dry_run)); then
    printf '[DRY] %s -> %s\n' "$source" "$target"
    return
  fi
  backup_file "$target"
  install -Dm"$3" -- "$source" "$target"
}

while IFS= read -r -d '' source; do
  relative="${source#"$root/config/"}"
  case "$relative" in hypr/friend/input.lua|hypr/friend/monitor.lua) continue ;; esac
  copy_file "$source" "$HOME/.config/$relative" 0644
done < <(find "$root/config" -type f -print0 | sort -z)

while IFS= read -r -d '' source; do
  copy_file "$source" "$HOME/.local/bin/${source##*/}" 0755
done < <(find "$root/bin" -maxdepth 1 -type f -print0 | sort -z)

copy_file "$root/home/.zshrc" "$HOME/.zshrc" 0644

if [[ -d "$root/codex/home" ]]; then
  while IFS= read -r -d '' source; do
    relative="${source#"$root/codex/home/"}"
    copy_file "$source" "$HOME/.codex/$relative" 0644
  done < <(find "$root/codex/home" -type f -print0 | sort -z)
fi
if [[ -d "$root/codex/skills" ]]; then
  while IFS= read -r -d '' source; do
    relative="${source#"$root/codex/skills/"}"
    copy_file "$source" "$HOME/.codex/skills/$relative" 0644
  done < <(find "$root/codex/skills" -type f -print0 | sort -z)
fi

# Remove the two remaining Omarchy-only launcher calls from the shared rice.
launcher="$HOME/.config/quickshell/redesign/ui/Launcher.qml"
if [[ -f "$launcher" ]]; then
  if grep -qE 'omarchy-launch-screensaver|/\.config/scripts/random-wallpaper\.sh' "$launcher"; then
    if ((dry_run)); then
      printf '[DRY] patch portable launcher commands in %s\n' "$launcher"
    else
      backup_file "$launcher"
      sed -i \
        -e 's|cmd: \["omarchy-launch-screensaver", "force"\]|cmd: [home + "/.local/bin/lock-screen"]|' \
        -e 's|home + "/.config/scripts/random-wallpaper.sh"|home + "/.local/bin/random-wallpaper"|' \
        "$launcher"
    fi
  fi
fi

if ((dry_run)); then
  printf '%s\n' '[DRY] Config sync complete; no files changed.'
else
  printf 'Config sync complete. Replaced files backed up under %s\n' "$backup"
  if command -v hyprctl >/dev/null 2>&1 && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
    hyprctl reload >/dev/null || true
  fi
fi
