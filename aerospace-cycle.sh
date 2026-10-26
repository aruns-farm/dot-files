#!/usr/bin/env bash
# Cycles AeroSpace workspaces 1 → 2 → 3 → 1 … every 90 seconds.
# Also jiggles the mouse, clicks, and scrolls at each switch.
# Usage: ./aerospace-cycle.sh [--interval <seconds>]

INTERVAL=90
WORKSPACES=(1 2 3)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interval|-i) INTERVAL="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

trap 'echo; echo "Stopped."; exit 0' INT TERM

# Compile swift helper on first run
JIGGLE_SRC="$(dirname "$0")/mouse-jiggle.swift"
JIGGLE_BIN="$HOME/.local/bin/mouse-jiggle"

if [[ ! -f "$JIGGLE_BIN" && -f "$JIGGLE_SRC" ]]; then
  echo "Compiling mouse-jiggle helper…"
  mkdir -p "$HOME/.local/bin"
  swiftc -O "$JIGGLE_SRC" -o "$JIGGLE_BIN" && echo "Done." || echo "swiftc failed — mouse actions disabled."
fi

jiggle() {
  [[ -x "$JIGGLE_BIN" ]] && "$JIGGLE_BIN" &
}

echo "Cycling workspaces [${WORKSPACES[*]}] randomly every ${INTERVAL}s — Ctrl-C to stop."

current=""
while true; do
  # Pick a random workspace that differs from the current one
  while true; do
    ws="${WORKSPACES[$(( RANDOM % ${#WORKSPACES[@]} ))]}"
    [[ "$ws" != "$current" ]] && break
  done
  current="$ws"
  aerospace workspace "$ws"
  echo "$(date '+%H:%M:%S')  → workspace $ws"
  jiggle
  sleep "$INTERVAL"
done
