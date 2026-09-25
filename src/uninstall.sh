#!/bin/bash
# Remove the boot LaunchDaemon and unblock all sites.

LIB_DIR="/usr/local/lib/focus"
LABEL="com.klemen.focus"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

launchctl bootout "system/$LABEL" 2>/dev/null
rm -f "$PLIST"
rm -rf "$LIB_DIR"

PID_FILE="/var/run/focus.pid"
[ -f "$PID_FILE" ] && kill "$(cat "$PID_FILE")" 2>/dev/null
rm -f "$PID_FILE"

cat "$SCRIPT_DIR/hosts.base" > /etc/hosts
dscacheutil -flushcache 2>/dev/null
killall -HUP mDNSResponder 2>/dev/null

echo "Uninstalled: sites are unblocked and won't be blocked at boot."
