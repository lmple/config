#!/usr/bin/env bash
# Waybar's custom/gpu module (waybar/config.jsonc): usage and VRAM of each
# NVIDIA or AMD GPU, hidden on a machine without one. VRAM is shown in the
# bar, not only usage, because llama-server keeps its model there: it says
# whether another model or program still fits.
#
# Only GPUs with a readout count: NVIDIA through nvidia-smi, AMD through
# amdgpu's sysfs files. An Intel iGPU has none without root, so it's left out.
#
# A laptop's dGPU sleeps when unused (runtime suspend), and nvidia-smi wakes
# it: polled every few seconds, it would never sleep again and drain the
# battery. So a suspended GPU is shown as off and never queried.
#
# SYSFS and NVIDIA_SMI are only there to test the script against a fake tree.
set -euo pipefail

readonly SYSFS="${SYSFS:-/sys}"
readonly NVIDIA_SMI="${NVIDIA_SMI:-nvidia-smi}"

# The display controllers of the vendors with a readout, one
# "vendor address device-dir" per line
gpus() {
  local dev class vendor
  for dev in "$SYSFS"/bus/pci/devices/*; do
    class="$(cat "$dev/class" 2>/dev/null)" || continue
    [[ "$class" == 0x03* ]] || continue
    vendor="$(cat "$dev/vendor" 2>/dev/null)" || continue
    case "$vendor" in
      0x10de) printf 'nvidia %s %s\n' "${dev##*/}" "$dev" ;;
      0x1002) printf 'amd %s %s\n' "${dev##*/}" "$dev" ;;
    esac
  done
}

asleep() {
  [[ "$(cat "$1/power/runtime_status" 2>/dev/null)" == suspended ]]
}

# Every awake NVIDIA GPU at the addresses given, one JSON object per line.
# One nvidia-smi call for all cards, and one for the processes; their bus ids
# have an 8-digit domain where sysfs has 4, hence the last 12 characters.
nvidia() {
  local addresses gpus_csv apps_csv
  command -v "$NVIDIA_SMI" >/dev/null || return 0 # driver not installed
  addresses="$(printf '%s\n' "$@")"
  gpus_csv="$("$NVIDIA_SMI" --format=csv,noheader,nounits \
    --query-gpu=pci.bus_id,name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw)" ||
    return 0
  apps_csv="$("$NVIDIA_SMI" --format=csv,noheader,nounits \
    --query-compute-apps=gpu_bus_id,process_name,used_memory 2>/dev/null)" || apps_csv=""
  jq -nc --arg gpus "$gpus_csv" --arg apps "$apps_csv" --arg want "$addresses" '
    def rows: split("\n") | map(select(. != "") | split(", "));
    def addr: ascii_downcase | .[-12:];
    def num: tonumber? // null;
    ($want | split("\n")) as $want
    | ($apps | rows | map({addr: (.[0] | addr), name: (.[1] | split("/")[-1]),
                           mib: (.[2] | num)})) as $apps
    | $gpus | rows[]
    | (.[0] | addr) as $addr
    | select($want | index($addr))
    | {name: .[1], util: (.[2] | num), used: (.[3] | num), total: (.[4] | num),
       temp: (.[5] | num), power: (.[6] | num),
       procs: [$apps[] | select(.addr == $addr) | {name, mib}]}'
}

# A sysfs number, or null when the file is missing (an older kernel)
read_or_null() { cat "$1" 2>/dev/null || echo null; }

# One awake AMD GPU, from amdgpu's sysfs files in its PCI device directory
# (bytes, millidegrees, µW)
amd() {
  local dev=$1 hwmon name
  [[ -r "$dev/gpu_busy_percent" ]] || return 0 # not amdgpu
  hwmon="$(find "$dev/hwmon" -mindepth 1 -maxdepth 1 2>/dev/null | head -n1)"
  name="$(cat "$dev/product_name" 2>/dev/null || true)"
  jq -nc --arg name "${name:-AMD GPU}" \
    --argjson util "$(read_or_null "$dev/gpu_busy_percent")" \
    --argjson used "$(read_or_null "$dev/mem_info_vram_used")" \
    --argjson total "$(read_or_null "$dev/mem_info_vram_total")" \
    --argjson temp "$(read_or_null "$hwmon/temp1_input")" \
    --argjson power "$(read_or_null "$hwmon/power1_average")" '
    def mib: if . == null then null else . / 1048576 end;
    {name: $name, util: $util, used: ($used | mib), total: ($total | mib),
     temp: (if $temp == null then null else $temp / 1000 end),
     power: (if $power == null then null else $power / 1000000 end),
     procs: []}'
}

# Each GPU as one JSON object per line, {asleep: true} for a sleeping one
readings() {
  local vendor addr dev nvidia_awake=()
  while read -r vendor addr dev; do
    if asleep "$dev"; then
      jq -nc --arg v "$vendor" '{asleep: true, name: (if $v == "nvidia" then "NVIDIA GPU" else "AMD GPU" end)}'
    elif [[ "$vendor" == nvidia ]]; then
      nvidia_awake+=("$addr")
    else
      amd "$dev"
    fi
  done < <(gpus)
  ((${#nvidia_awake[@]} == 0)) || nvidia "${nvidia_awake[@]}"
}

readings | jq -sc '
  def esc: gsub("&"; "&amp;") | gsub("<"; "&lt;") | gsub(">"; "&gt;");
  def gib: if . == null then "?" else (. / 1024 * 10 | round / 10 | tostring
           | if test("\\.") then . else . + ".0" end) end;
  def or_q: if . == null then "?" else (round | tostring) end;
  def full: .asleep != true and .used != null and .total != null
            and .total > 0 and .used / .total >= 0.9;
  def busy: .asleep != true and (.util // 0) >= 50;
  if length == 0 then {text: "", tooltip: "", class: "none"} else
  # Font Awesome microchip glyph of the Nerd Font, as the bar shows it
  {text: (map(if .asleep then " off"
              else " \(.util | or_q)%  \(.used | gib)/\(.total | gib)G" end)
          | join("  ")),
   class: (if any(full) then "full" elif any(busy) then "busy"
           elif all(.asleep == true) then "asleep" else "idle" end),
   tooltip: (map(if .asleep then "\(.name)\nAsleep, not polled so it stays asleep"
                 else "\(.name)\nUsage \(.util | or_q)%   Temp \(.temp | or_q)°C   Power \(.power | or_q) W\nVRAM \(.used | gib) / \(.total | gib) GiB"
                      + (.procs | map("\n  \(.name)  \(.mib | gib) GiB") | join(""))
                 end | esc)
             | join("\n\n"))}
  end'
