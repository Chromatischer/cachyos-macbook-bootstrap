#!/usr/bin/env bash
set -Eeuo pipefail

# This report avoids serial numbers, UUIDs, MAC addresses, IPs, SSIDs, and logs.
output="${1:-hardware-report-linux.txt}"

{
  printf 'timestamp_utc=%s\n' "$(date -u +%FT%TZ)"
  printf 'kernel=%s\n' "$(uname -sr)"
  printf 'architecture=%s\n' "$(uname -m)"
  if [[ -r /etc/os-release ]]; then
    awk -F= '/^(NAME|VERSION|ID)=/ {print tolower($1) "=" $2}' /etc/os-release
  fi
  for field in product_name product_version board_name; do
    path="/sys/devices/virtual/dmi/id/$field"
    [[ -r "$path" ]] && printf '%s=%s\n' "$field" "$(<"$path")"
  done
  printf '\n[pci]\n'
  lspci -nnk 2>/dev/null || true
  printf '\n[usb-device-classes]\n'
  lsusb 2>/dev/null | sed -E 's/(iSerial|SerialNumber)=?[^ ]*/\1=<omitted>/g' || true
  printf '\n[rfkill]\n'
  rfkill list 2>/dev/null || true
  printf '\n[drm-connectors]\n'
  find /sys/class/drm -maxdepth 1 -type l -printf '%f\n' 2>/dev/null | sort || true
  printf '\n[audio]\n'
  wpctl status 2>/dev/null | sed -n '1,100p' || true
} > "$output"

echo "Wrote $output"
echo 'Review the file before sharing it. It should contain hardware, not account data.'

