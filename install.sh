#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROFILE_FILE="$ROOT_DIR/profile.env"
DRY_RUN=0

usage() {
  printf '%s\n' \
    'Usage: ./install.sh [--dry-run] [--profile FILE]' \
    '' \
    'Post-install bootstrap for an x86_64 CachyOS system.' \
    'It does not partition disks, install a bootloader, or apply model-specific drivers.'
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --profile)
      [[ $# -ge 2 ]] || { echo 'error: --profile requires a file' >&2; exit 2; }
      PROFILE_FILE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [[ -r "$PROFILE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$PROFILE_FILE"
elif [[ "$PROFILE_FILE" != "$ROOT_DIR/profile.env" ]]; then
  echo "error: profile not readable: $PROFILE_FILE" >&2
  exit 1
fi

MAC_MODEL="${MAC_MODEL:-UNKNOWN}"
HAS_T2="${HAS_T2:-auto}"
KEYBOARD_LAYOUT="${KEYBOARD_LAYOUT:-us}"
KEYBOARD_OPTIONS="${KEYBOARD_OPTIONS:-compose:caps}"
INSTALL_DESKTOP="${INSTALL_DESKTOP:-1}"
INSTALL_DEVELOPMENT="${INSTALL_DEVELOPMENT:-1}"
INSTALL_OPTIONAL_APPS="${INSTALL_OPTIONAL_APPS:-1}"
INSTALL_AUR_APPS="${INSTALL_AUR_APPS:-1}"
INSTALL_CODEX="${INSTALL_CODEX:-1}"
INSTALL_CODEX_CONFIG="${INSTALL_CODEX_CONFIG:-1}"
SET_ZSH_AS_LOGIN_SHELL="${SET_ZSH_AS_LOGIN_SHELL:-1}"
INTERNAL_DISPLAY_SCALE="${INTERNAL_DISPLAY_SCALE:-auto}"

STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/cachyos-macbook-bootstrap"
RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)-$$"
BACKUP_DIR="$STATE_HOME/backups/$RUN_STAMP"
LOG_FILE="$STATE_HOME/install-$RUN_STAMP.log"

info() { printf '[INFO] %s\n' "$*"; }
warn() { printf '[WARN] %s\n' "$*" >&2; }
die() { printf '[ERROR] %s\n' "$*" >&2; exit 1; }

quote_cmd() {
  printf ' %q' "$@"
  printf '\n'
}

run() {
  if ((DRY_RUN)); then
    printf '[DRY]'
    quote_cmd "$@"
  else
    "$@"
  fi
}

enabled() { [[ "${1:-0}" == 1 ]]; }

load_packages() {
  local file=$1 line
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -n "$line" ]] && printf '%s\n' "$line"
  done < "$file"
}

preflight() {
  [[ $EUID -ne 0 ]] || die 'Run this as the target user, not as root.'
  [[ $(uname -m) == x86_64 ]] || die 'This bundle is for Intel/AMD x86_64 only.'
  [[ -r /etc/os-release ]] || die 'Cannot identify the operating system.'

  # shellcheck disable=SC1091
  source /etc/os-release
  if [[ "${ID:-}" != cachyos ]]; then
    die "Expected CachyOS (ID=cachyos); detected ${PRETTY_NAME:-unknown}."
  fi

  command -v pacman >/dev/null || die 'pacman is required.'
  command -v sudo >/dev/null || die 'sudo is required.'

  case "$HAS_T2" in auto|yes|no) ;; *) die 'HAS_T2 must be auto, yes, or no.' ;; esac
  [[ "$KEYBOARD_LAYOUT" =~ ^[A-Za-z0-9_,+-]+$ ]] ||
    die 'KEYBOARD_LAYOUT contains unsupported characters.'
  [[ "$KEYBOARD_OPTIONS" =~ ^[-A-Za-z0-9_,:+]*$ ]] ||
    die 'KEYBOARD_OPTIONS contains unsupported characters.'
  if [[ "$MAC_MODEL" == UNKNOWN ]]; then
    warn 'MAC_MODEL is still UNKNOWN. Common setup may continue; no Mac driver decisions will be made.'
  fi
  if [[ "$HAS_T2" == auto ]]; then
    warn 'HAS_T2 is auto. This installer will not guess or modify T2 firmware support.'
  fi

  if [[ "$INTERNAL_DISPLAY_SCALE" != auto ]] &&
     ! [[ "$INTERNAL_DISPLAY_SCALE" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    die 'INTERNAL_DISPLAY_SCALE must be auto or a positive number.'
  fi
  if [[ "$INTERNAL_DISPLAY_SCALE" =~ ^0+([.]0+)?$ ]]; then
    die 'INTERNAL_DISPLAY_SCALE must be greater than zero.'
  fi

  info "Target: ${MAC_MODEL}; T2=${HAS_T2}; keyboard=${KEYBOARD_LAYOUT}; user=${USER}"
  info 'Scope: packages, user configs, services, and optional Codex setup only.'
  info 'Disk partitions, boot entries, firmware, and GPU/Wi-Fi drivers are out of scope.'

  if ((DRY_RUN == 0)); then
    mkdir -p "$STATE_HOME" "$BACKUP_DIR"
    : > "$LOG_FILE"
    sudo -v
  fi
}

install_repo_packages() {
  local -a requested=() available=() missing=()
  local pkg

  enabled "$INSTALL_DESKTOP" && mapfile -t requested < <(load_packages "$ROOT_DIR/packages/desktop.txt")
  if enabled "$INSTALL_DEVELOPMENT"; then
    mapfile -t _dev < <(load_packages "$ROOT_DIR/packages/development.txt")
    requested+=("${_dev[@]}")
  fi
  if enabled "$INSTALL_OPTIONAL_APPS"; then
    mapfile -t _apps < <(load_packages "$ROOT_DIR/packages/optional.txt")
    requested+=("${_apps[@]}")
  fi

  ((${#requested[@]})) || { info 'No repository package groups selected.'; return; }

  info 'Refreshing the system before package installation.'
  run sudo pacman -Syu --noconfirm

  if ((DRY_RUN)); then
    info "Would resolve and install ${#requested[@]} repository packages."
    printf '  %s\n' "${requested[@]}"
    return
  fi

  for pkg in "${requested[@]}"; do
    if pacman -Si -- "$pkg" >/dev/null 2>&1; then
      available+=("$pkg")
    else
      missing+=("$pkg")
    fi
  done

  if ((${#available[@]})); then
    sudo pacman -S --needed --noconfirm -- "${available[@]}" 2>&1 | tee -a "$LOG_FILE"
  fi
  if ((${#missing[@]})); then
    warn "Unavailable repository packages (skipped): ${missing[*]}"
  fi
}

install_aur_packages() {
  enabled "$INSTALL_AUR_APPS" || return 0
  local helper=''
  if command -v paru >/dev/null; then helper=paru
  elif command -v yay >/dev/null; then helper=yay
  else
    if ((DRY_RUN)); then
      info 'Would build yay from its reviewed AUR PKGBUILD before installing AUR apps.'
      helper=yay
    else
      local yay_build
      yay_build="$(mktemp -d)"
      info 'No AUR helper found; bootstrapping yay as the target user.'
      git clone --depth 1 https://aur.archlinux.org/yay.git "$yay_build/yay"
      (cd "$yay_build/yay" && makepkg -si --needed --noconfirm)
      helper=yay
    fi
  fi

  local -a packages=()
  mapfile -t packages < <(load_packages "$ROOT_DIR/packages/aur.txt")
  ((${#packages[@]})) || return 0
  run "$helper" -S --needed --noconfirm -- "${packages[@]}"
}

backup_target() {
  local target=$1 relative
  [[ -e "$target" || -L "$target" ]] || return 0
  relative="${target#/}"
  run mkdir -p "$BACKUP_DIR/$(dirname -- "$relative")"
  run cp -a -- "$target" "$BACKUP_DIR/$relative"
}

deploy_tree() {
  local source_root=$1 target_root=$2 mode=$3 source relative target
  [[ -d "$source_root" ]] || return 0
  while IFS= read -r -d '' source; do
    relative="${source#"$source_root"/}"
    target="$target_root/$relative"
    backup_target "$target"
    run install -Dm"$mode" -- "$source" "$target"
  done < <(find "$source_root" -type f -print0 | sort -z)
}

deploy_configs() {
  enabled "$INSTALL_DESKTOP" || return 0
  info "Backing up replaced files under $BACKUP_DIR"
  deploy_tree "$ROOT_DIR/config" "$HOME/.config" 0644
  deploy_tree "$ROOT_DIR/bin" "$HOME/.local/bin" 0755
  if [[ -f "$ROOT_DIR/home/.zshrc" ]]; then
    backup_target "$HOME/.zshrc"
    run install -Dm0644 -- "$ROOT_DIR/home/.zshrc" "$HOME/.zshrc"
  fi

  local input_file="$HOME/.config/hypr/friend/input.lua"
  if ((DRY_RUN)); then
    printf '[DRY] write keyboard layout %q and options %q to %q\n' \
      "$KEYBOARD_LAYOUT" "$KEYBOARD_OPTIONS" "$input_file"
  else
    printf '%s\n' \
      'hl.config({' \
      '    input = {' \
      "        kb_layout = \"$KEYBOARD_LAYOUT\"," \
      "        kb_options = \"$KEYBOARD_OPTIONS\"," \
      '        repeat_rate = 40,' \
      '        repeat_delay = 600,' \
      '        follow_mouse = 1,' \
      '        sensitivity = 0,' \
      '        touchpad = {' \
      '            natural_scroll = true,' \
      '            tap_to_click = true,' \
      '            clickfinger_behavior = true,' \
      '            scroll_factor = 0.55,' \
      '        },' \
      '    },' \
      '})' \
      '' \
      'hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })' \
      > "$input_file"
  fi

  if [[ "$INTERNAL_DISPLAY_SCALE" != auto ]]; then
    local monitor_file="$HOME/.config/hypr/friend/monitor.lua"
    if ((DRY_RUN)); then
      printf '[DRY] write monitor scale %q to %q\n' "$INTERNAL_DISPLAY_SCALE" "$monitor_file"
    else
      printf '%s\n' \
        'hl.monitor({' \
        '    output = "",' \
        '    mode = "preferred",' \
        '    position = "auto",' \
        "    scale = $INTERNAL_DISPLAY_SCALE," \
        '})' > "$monitor_file"
    fi
  fi
}

install_quickshell_rice() {
  enabled "$INSTALL_DESKTOP" || return 0
  local target="$HOME/.config/quickshell/redesign"
  if [[ -f "$target/shell.qml" ]]; then
    info 'Quickshell rice is already present.'
  else
    backup_target "$target"
    if ((DRY_RUN)); then
      info "Would clone the reviewed public Quickshell rice into $target."
      return 0
    else
      run git clone --depth 1 \
        https://github.com/Chromatischer/quickshell-redesign.git "$target"
    fi
  fi

  local settings="$target/services/Settings.qml"
  local shell="$target/shell.qml"
  local launcher="$target/ui/Launcher.qml"
  local ipc_part="$ROOT_DIR/system/quickshell-notifications-ipc.qmlpart"
  if ((DRY_RUN)); then
    info 'Would apply the portable brightness and notification command bridges.'
    return 0
  fi

  if [[ -f "$settings" ]]; then
    backup_target "$settings"
    sed -i 's|brightnessctl -m 2>/dev/null|q-brightness get 2>/dev/null|' "$settings"
    sed -i 's|brightProc.command = \["brightnessctl", "-q", "set", root.brightness + "%"\]|brightProc.command = ["q-brightness", "set", root.brightness]|' "$settings"
  fi
  if [[ -f "$shell" && -f "$ipc_part" ]] && ! grep -q 'target: "notifications"' "$shell"; then
    backup_target "$shell"
    sed -i "/Notifications { id: notifSvc }/r $ipc_part" "$shell"
  fi
  if [[ -f "$launcher" ]]; then
    backup_target "$launcher"
    sed -i \
      -e 's|cmd: \["omarchy-launch-screensaver", "force"\]|cmd: [home + "/.local/bin/lock-screen"]|' \
      -e 's|home + "/.config/scripts/random-wallpaper.sh"|home + "/.local/bin/random-wallpaper"|' \
      "$launcher"
  fi
}

install_codex() {
  if enabled "$INSTALL_CODEX"; then
    if command -v codex >/dev/null; then
      info "Codex already installed: $(codex --version 2>/dev/null || echo unknown-version)"
    elif ((DRY_RUN)); then
      info 'Would download and run the official Codex standalone installer from chatgpt.com.'
    else
      local temp_dir installer
      temp_dir="$(mktemp -d)"
      installer="$temp_dir/codex-install.sh"
      trap 'rm -rf -- "$temp_dir"' RETURN
      curl -fsSL https://chatgpt.com/codex/install.sh -o "$installer"
      sh "$installer"
      rm -rf -- "$temp_dir"
      trap - RETURN
    fi
  fi

  if enabled "$INSTALL_CODEX_CONFIG"; then
    deploy_tree "$ROOT_DIR/codex/home" "$HOME/.codex" 0644
    deploy_tree "$ROOT_DIR/codex/skills" "$HOME/.codex/skills" 0644
  fi
}

configure_system() {
  if enabled "$INSTALL_DESKTOP"; then
    run sudo systemctl enable --now NetworkManager.service
    if systemctl list-unit-files bluetooth.service >/dev/null 2>&1; then
      run sudo systemctl enable --now bluetooth.service
    fi
  fi

  if [[ "$HAS_T2" == yes ]]; then
    run sudo install -Dm0644 "$ROOT_DIR/system/90-t2-backlight.rules" \
      /etc/udev/rules.d/90-t2-backlight.rules
    run sudo install -Dm0644 "$ROOT_DIR/system/90-t2-lid.conf" \
      /etc/systemd/logind.conf.d/90-t2-lid.conf
    run sudo install -Dm0644 "$ROOT_DIR/system/20-t2-hardware.conf" \
      /etc/limine-entry-tool.d/20-t2-hardware.conf
    run sudo udevadm control --reload-rules
    run sudo udevadm trigger --subsystem-match=backlight --action=add
    run sudo udevadm trigger --subsystem-match=leds --action=add
    if command -v limine-mkinitcpio >/dev/null 2>&1; then
      run sudo limine-mkinitcpio
    fi
    warn 'T2 lid safety policy installed; reboot before closing the lid.'
  fi

  if enabled "$INSTALL_DEVELOPMENT" && getent group docker >/dev/null 2>&1; then
    run sudo usermod -aG docker "$USER"
    run sudo systemctl enable --now docker.service
  fi

  if enabled "$SET_ZSH_AS_LOGIN_SHELL" && command -v zsh >/dev/null; then
    local zsh_path
    zsh_path="$(command -v zsh)"
    if [[ "$(getent passwd "$USER" | cut -d: -f7)" != "$zsh_path" ]]; then
      run sudo usermod --shell "$zsh_path" "$USER"
    fi
  fi
}

finish() {
  info 'Bootstrap complete.'
  if ((DRY_RUN)); then
    info 'No changes were made. Re-run without --dry-run when the plan looks right.'
    return
  fi
  info "Log: $LOG_FILE"
  info "Backups: $BACKUP_DIR"
  info 'Log out and choose the Hyprland (UWSM) session, then run scripts/linux-hardware-report.sh.'
  enabled "$INSTALL_CODEX" && info 'Run codex once and sign in with the new owner’s own account.'
}

preflight
install_repo_packages
install_aur_packages
deploy_configs
install_quickshell_rice
install_codex
configure_system
finish
