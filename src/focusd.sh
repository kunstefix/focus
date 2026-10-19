#!/bin/bash
# Run by the LaunchDaemon (see install.sh): block at boot, then end each break
# once its deadline passes. Polls the wall clock, so time the Mac spends asleep
# counts towards the break. launchd owns this process, so it doesn't matter
# whether the break was started from the CLI or the app.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Boot ends any break that was running
"$SCRIPT_DIR/focus.sh"

while true; do
    sleep 5
    [ -f "$DEADLINE_FILE" ] || continue
    read -r _ deadline _ < "$DEADLINE_FILE"
    [ "$(date +%s)" -ge "${deadline:-0}" ] && "$SCRIPT_DIR/focus.sh"
done
