#!/bin/bash
set -eu

# Read-only, privacy-minimized report. It deliberately omits serial numbers,
# hardware UUIDs, disk volume names, network addresses, and account names.
output="${1:-hardware-report-macos.txt}"

model_identifier="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Identifier/ {print $2; exit}')"
model_name="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Model Name/ {print $2; exit}')"
processor="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Processor Name/ {print $2; exit}')"
memory="$(system_profiler SPHardwareDataType 2>/dev/null | awk -F': ' '/Memory/ {print $2; exit}')"

if system_profiler SPiBridgeDataType 2>/dev/null | grep -qi 'Apple T2'; then
  has_t2=yes
else
  has_t2=no
fi

{
  echo "model_name=${model_name:-unknown}"
  echo "model_identifier=${model_identifier:-unknown}"
  echo "processor=${processor:-unknown}"
  echo "memory=${memory:-unknown}"
  echo "has_t2=$has_t2"
  echo "macos_version=$(sw_vers -productVersion 2>/dev/null || echo unknown)"
} > "$output"

echo "Wrote $output"
echo 'Review the file, then send it to the installer maintainer.'

