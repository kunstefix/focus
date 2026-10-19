#!/bin/bash
# Remove the boot LaunchDaemon, the installed scripts and the sudoers rule, and unblock all sites.
# The break log in /var/db/focus is kept.

LABEL="io.github.kunstefix.focus"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
LEGACY_LABEL="com.klemen.focus"  # label before the rename
SUDOERS_FILE="/etc/sudoers.d/focus"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

for label in "$LABEL" "$LEGACY_LABEL"; do
    launchctl bootout "system/$label" 2>/dev/null
    rm -f "/Library/LaunchDaemons/$label.plist"
    rm -rf "/Library/PrivilegedHelperTools/$label"
done
rm -f "$SUDOERS_FILE"
rm -rf /usr/local/lib/focus

end_break

hosts_without_block | replace_hosts
flush_dns

echo "Uninstalled: sites are unblocked and won't be blocked at boot."
