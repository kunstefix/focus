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

# Re-run as root, always asking for the password: -k ignores sudo's cached
# credentials, so a recent sudo doesn't let a break start without a prompt.
[ "$EUID" -eq 0 ] || exec sudo -k "$0" "$@"

# A second unfocus restarts the countdown
cancel_timer

hosts_without_block | replace_hosts
flush_dns

# Poll a wall-clock deadline instead of one long sleep, so time the
# machine spends asleep still counts towards the break.
now=$(date +%s)
deadline=$(( now + minutes * 60 ))
echo "$now $deadline" > "$DEADLINE_FILE"
log_event "start $now $deadline"

# The app runs this through osascript, where SUDO_USER isn't set, and passes FOCUS_USER
nohup bash -c '
    while [ "$(date +%s)" -lt "$1" ]; do sleep 5; done
    rm -f "$2"
    echo "end $1" >> "$5"
    "$3/focus.sh"
    exec "$3/restart-chrome.sh" "$4"
' _ "$deadline" "$PID_FILE" "$SCRIPT_DIR" "${SUDO_USER:-$FOCUS_USER}" "$LOG_FILE" >/dev/null 2>&1 &
echo $! > "$PID_FILE"

echo "Focus off: sites are unblocked until $(date -r "$deadline" +%H:%M)."

exit 0
