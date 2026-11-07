#!/bin/bash
# Types through real sessions in the vinyl manager and keeps a screenshot of each.
#
#   tools/vinyl_sessions.sh DISK.dsk [SESSION...]
set -euo pipefail

disk=$(realpath "$1"); shift
here=$(dirname "$(realpath "$0")")
shots=$here/../screenshots

# Autotyping loses keys if text arrives while the CPC is busy, and a CAP32_DELAY on
# a line of its own would also answer a prompt with Return. So the waits go at the
# start of the same line as the text they protect.
wait_short=$(printf 'CAP32_DELAY%.0s' {1..12})
wait_load=$(printf 'CAP32_DELAY%.0s' {1..60})

# session NAME [DISK] ANSWER...   starts the program and answers each prompt in turn.
# The screenshot is taken at the prompt after the last answer.
session() {
  local name=$1 image=$2; shift 2
  local script='run"vinyl"' first=1 answer
  for answer in "$@"; do
    if [ $first = 1 ]; then script+=$'\n'"$wait_load$answer"; first=0
    else script+=$'\n'"$wait_short$answer"; fi
  done
  "$here/shot.sh" "$image" "$script" "$shots/vinyl_$name.png" 30
}

wanted=" $* "
run() { [ "$wanted" = "  " ] || [[ $wanted == *" $1 "* ]]; }

copy=$disk

run menu    && session menu    "$copy" ""
run list    && session list    "$copy" 1
run sort    && session sort    "$copy" 6 3
run rating  && session rating  "$copy" 6 4
run search  && session search  "$copy" 5 moon
run none    && session none    "$copy" 5 zzz
run stats   && session stats   "$copy" 7
# Bad year and rating are refused, then accepted. A double quote gets cleaned.
run add     && session add     "$copy" 2 'Can' 'Tago "Mago"' 'Krautrock' 1800 1971 9 5
run added   && session added   "$copy" 2 'Can' 'Tago "Mago"' 'Krautrock' 1971 5 "" 1
run edit    && session edit    "$copy" 3 2 "" "Kind of Blue (mono)" "" 1960 4 "" 1
run remove  && session remove  "$copy" 4 1 y "" 1
run keep    && session keep    "$copy" 4 1 n 1
run nofile  && session nofile  "$copy" 9
# Save, damage the collection, load it back: the added record must return and the
# removed one too. All in one run, as the emulator keeps a written disk in memory.
add=(2 Can 'Tago Mago' Krautrock 1971 5 "")
run save    && session save    "$copy" "${add[@]}" 8
run load    && session load    "$copy" "${add[@]}" 8 "" 4 1 y "" 9 "" 1
run resave  && session resave  "$copy" 8 "" 8
# More records than one screen holds: the list must pause, then show the rest.
more=()
for i in 1 2 3 4 5 6; do more+=(2 "Artist $i" "Album $i" Test 1980 3 ""); done
run page1   && session page1   "$copy" "${more[@]}" 1
run page2   && session page2   "$copy" "${more[@]}" 1 ""
run numbers && session numbers "$copy" "${more[@]}" 3
run quit    && session quit    "$copy" q y
exit 0
