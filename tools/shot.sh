#!/bin/bash
# Run a CPC command in Caprice32 without opening a window, and keep a screenshot.
#
#   tools/shot.sh DISK.dsk 'BASIC COMMANDS' OUTPUT.png [--wait-break | DELAYS]
#
# COMMANDS      one per line, each is typed followed by Return
# --wait-break  the program signals it is done by running CALL 0 (see src/test.bas)
# DELAYS        otherwise, how many CAP32_DELAY waits before the screenshot (default 40)
set -euo pipefail

disk=$(realpath "$1")
command=$2
out=$3
mode=${4:-40}

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Each -a ends with Return, which would dismiss a "press a key" prompt, so the
# waits and the screenshot share one -a. After CALL 0 the screen is wiped almost
# at once, which is another reason the screenshot must directly follow the wait.
args=()
while IFS= read -r line; do args+=(-a "$line"); done <<<"$command"
if [ "$mode" = --wait-break ]; then
  args+=(-a 'CAP32_WAITBREAKCAP32_SCRNSHOT CAP32_EXIT')
else
  waits=""
  for ((i = 0; i < mode; i++)); do waits+=CAP32_DELAY; done
  args+=(-a "${waits}CAP32_SCRNSHOT CAP32_EXIT")
fi

# If the program wrote to the disk, Caprice32 answers CAP32_EXIT with a "quit without
# saving?" dialog that nobody can answer here. So stop it as soon as the screenshot
# exists. Stopping it this way also leaves the disk image file unmodified.
SDL_VIDEODRIVER=dummy SDL_AUDIODRIVER=dummy timeout 120 cap32 \
  -O system.model=2 -O system.limit_speed=0 -O sound.enabled=0 -O video.scr_fps=0 \
  -O file.sdump_dir="$work" "${args[@]}" "$disk" >"$work/log" 2>&1 &
emulator=$!
shot=""
while kill -0 "$emulator" 2>/dev/null; do
  shot=$(find "$work" -name '*.png' | head -1)
  [ -z "$shot" ] || break
  sleep 0.2
done
[ -n "$shot" ] || shot=$(find "$work" -name '*.png' | head -1)
sleep 0.2                 # let the file finish being written
kill "$emulator" 2>/dev/null || true
wait "$emulator" 2>/dev/null || true
[ -n "$shot" ] || { echo "no screenshot was produced:" >&2; tail -5 "$work/log" >&2; exit 1; }
mkdir -p "$(dirname "$out")"
cp "$shot" "$out"
echo "$out"
