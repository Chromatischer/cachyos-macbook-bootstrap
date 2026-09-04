#!/usr/bin/env bash
# Capture only the explicitly reviewed portable paths into this repository.
set -Eeuo pipefail

root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

config_paths=(
  alacritty/alacritty.toml
  fastfetch/config.jsonc
  fuzzel/fuzzel.ini
  ghostty/config
  hypr/hypridle.conf
  hypr/hyprland.lua
  hypr/hyprlock.conf
  hypr/friend/appearance.lua
  hypr/friend/autostart.lua
  hypr/friend/binds.lua
  hypr/friend/rules.lua
  kitty/kitty.conf
  mako/config
  omarchy/themes/aubergine.toml
  omarchy/themes/ember.toml
  omarchy/themes/graphite.toml
  omarchy/themes/moss.toml
  omarchy/themes/nocturne.toml
  omarchy/themes/sumi.toml
  rice/rice.txt
  starship.toml
  tmux/tmux.conf
  uwsm/env
  waybar/config.jsonc
  waybar/style.css
)

for relative in "${config_paths[@]}"; do
  source="$HOME/.config/$relative"
  [[ -f "$source" ]] || continue
  install -Dm0644 -- "$source" "$root/config/$relative"
done

while IFS= read -r -d '' tracked; do
  name="${tracked##*/}"
  [[ "$name" == q-update || "$name" == theme-apply ]] && continue
  source="$HOME/.local/bin/$name"
  [[ -f "$source" ]] && install -Dm0755 -- "$source" "$tracked"
done < <(find "$root/bin" -maxdepth 1 -type f -print0 | sort -z)

if [[ -f "$HOME/.zshrc" ]]; then
  install -Dm0644 -- "$HOME/.zshrc" "$root/home/.zshrc"
fi

printf '%s\n' 'Captured allow-listed config. Running privacy check...'
"$root/scripts/privacy-check.sh"
printf '%s\n' 'Capture complete. Machine-specific input/monitor, .zshrc.local, and all account state were skipped.'
