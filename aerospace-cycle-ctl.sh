#!/usr/bin/env bash
SCRIPT="$HOME/Documents/dot-files/aerospace-cycle.sh"
PIDFILE="/tmp/aerospace-cycle.pid"

notify() {
  osascript -e "display notification \"$1\" with title \"AeroSpace Cycle\""
}

case "$1" in
  start)
    if [[ -f "$PIDFILE" ]] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
      notify "Already running"
      exit 0
    fi
    bash "$SCRIPT" >> /tmp/aerospace-cycle.log 2>&1 &
    echo $! > "$PIDFILE"
    notify "Started"
    ;;
  stop)
    if [[ -f "$PIDFILE" ]]; then
      pid=$(cat "$PIDFILE")
      kill "$pid" 2>/dev/null
      rm -f "$PIDFILE"
    fi
    pkill -f "$SCRIPT" 2>/dev/null
    notify "Stopped"
    ;;
  *)
    echo "Usage: $0 start|stop"
    exit 1
    ;;
esac
