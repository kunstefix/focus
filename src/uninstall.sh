#!/bin/bash
# Remove the boot LaunchDaemon, the installed scripts and the sudoers rule, and unblock all sites.
# The break log in /var/db/focus is kept.

LABEL="com.klemen.focus"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
SUDOERS_FILE="/etc/sudoers.d/focus"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

launchctl bootout "system/$LABEL" 2>/dev/null
rm -f "$PLIST" "$SUDOERS_FILE"
rm -rf "$LIB_DIR" /usr/local/lib/focus

cancel_timer

hosts_without_block | replace_hosts
flush_dns

echo "Uninstalled: sites are unblocked and won't be blocked at boot."
