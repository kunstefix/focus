#!/bin/bash
# Unblock sites for a limited time, then re-block them automatically in the background.
# Usage: unfocus.sh [-m minutes]   (default: 5)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

minutes=5
while getopts "m:" opt; do
    case "$opt" in
        m) minutes="$OPTARG" ;;
        *) echo "Usage: $0 [-m minutes]"; exit 1 ;;
    esac
done

if ! [[ "$minutes" =~ ^[1-9][0-9]*$ ]]; then
    echo "Error: minutes must be a positive integer."
    exit 1
fi

require_root

# A second unfocus restarts the countdown
cancel_timer

cat "$BASE_HOSTS" > "$HOSTS_FILE"
flush_dns

# Poll a wall-clock deadline instead of one long sleep, so time the
# machine spends asleep still counts towards the break.
deadline=$(( $(date +%s) + minutes * 60 ))
nohup bash -c '
    while [ "$(date +%s)" -lt "$1" ]; do sleep 5; done
    rm -f "$2"
    exec "$3"
' _ "$deadline" "$PID_FILE" "$SCRIPT_DIR/focus.sh" >/dev/null 2>&1 &
echo $! > "$PID_FILE"

echo "Focus off: sites are unblocked until $(date -r "$deadline" +%H:%M)."

exit 0
