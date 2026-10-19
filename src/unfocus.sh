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

# The installed daemon is what ends the break
if [ ! -x "$LIB_DIR/focusd.sh" ]; then
    echo "Error: Focus isn't installed. Run: sudo ./src/install.sh"
    exit 1
fi

# Re-run as root, always asking for the password: -k ignores sudo's cached
# credentials, so a recent sudo doesn't let a break start without a prompt.
[ "$EUID" -eq 0 ] || exec sudo -k "$0" "$@"

# A second unfocus restarts the countdown
end_break

# Write the deadline before unblocking, so focusd.sh always ends the break.
# The user is who restart-browser.sh runs as; the app runs this through
# osascript, where SUDO_USER isn't set, and passes FOCUS_USER.
now=$(date +%s)
deadline=$(( now + minutes * 60 ))
echo "$now $deadline ${SUDO_USER:-$FOCUS_USER}" > "$DEADLINE_FILE"
log_event "start $now $deadline"

hosts_without_block | replace_hosts
flush_dns

echo "Focus off: sites are unblocked until $(date -r "$deadline" +%H:%M)."

exit 0
