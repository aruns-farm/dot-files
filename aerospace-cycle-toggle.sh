#!/usr/bin/env bash
SCRIPT="$HOME/Documents/dot-files/aerospace-cycle.sh"
PIDFILE="/tmp/aerospace-cycle.pid"

notify() {
  osascript -e "display notification \"$1\" with title \"AeroSpace Cycle\""
}

if [[ -f "$PIDFILE" ]]; then
  pid=$(cat "$PIDFILE")
  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    rm -f "$PIDFILE"
    notify "Stopped"
    exit 0
  else
    rm -f "$PIDFILE"
  fi
fi

# Detach fully: setsid puts it in its own process group so PID is stable
bash "$SCRIPT" >> /tmp/aerospace-cycle.log 2>&1 &
echo $! > "$PIDFILE"
notify "Started — switching randomly every 90s"
