#!/bin/bash
# Install the scripts and a LaunchDaemon that runs focus.sh at every boot, then focus immediately.
# Usage: sudo install.sh [sites-file]   (default: sites.txt in the repo root)

LABEL="com.klemen.focus"
PLIST="/Library/LaunchDaemons/$LABEL.plist"
SUDOERS_FILE="/etc/sudoers.d/focus"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

sites_file="${1:-$(dirname "$SCRIPT_DIR")/sites.txt}"
if [ ! -f "$sites_file" ]; then
    echo "Error: File '$sites_file' not found!"
    echo "Create it with: cp sites.example.txt sites.txt"
    exit 1
fi
sites_file="$(cd "$(dirname "$sites_file")" && pwd)/$(basename "$sites_file")"

# Root runs root-owned copies rather than the user-writable scripts in the
# repo or app bundle. The sites list is still read from where the user keeps it.
rm -rf /usr/local/lib/focus  # location used before the app existed
mkdir -p "$LIB_DIR"
cp "$SCRIPT_DIR/focus.sh" "$SCRIPT_DIR/unfocus.sh" "$SCRIPT_DIR/restart-chrome.sh" \
    "$SCRIPT_DIR/common.sh" "$LIB_DIR/"
printf 'SITES_FILE=%q\n' "$sites_file" > "$CONFIG_FILE"
chown -R root:wheel "$LIB_DIR"
chmod 755 "$LIB_DIR" "$LIB_DIR/focus.sh" "$LIB_DIR/unfocus.sh" "$LIB_DIR/restart-chrome.sh"
chmod 644 "$LIB_DIR/common.sh" "$CONFIG_FILE"

# Ending a break needs no password, so the app can do it without a prompt.
# The "" allows no arguments, so only the configured sites file is used.
tmp="$(mktemp)"
echo "ALL ALL=(root) NOPASSWD: $LIB_DIR/focus.sh \"\"" > "$tmp"
if ! visudo -cf "$tmp" >/dev/null; then
    rm -f "$tmp"
    echo "Error: generated sudoers rule is invalid."
    exit 1
fi
install -m 440 -o root -g wheel "$tmp" "$SUDOERS_FILE"
rm -f "$tmp"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
chmod 755 "$LOG_DIR"
chmod 644 "$LOG_FILE"

cat > "$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$LABEL</string>
    <key>ProgramArguments</key>
    <array>
        <string>$LIB_DIR/focus.sh</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
chown root:wheel "$PLIST"
chmod 644 "$PLIST"

# Older versions rewrote /etc/hosts with a "# Blocked sites" section at the
# end and no markers. Drop it once, so it isn't kept as a user entry.
if ! grep -qx "$BLOCK_BEGIN" "$HOSTS_FILE" && grep -qx "# Blocked sites" "$HOSTS_FILE"; then
    sed '/^# Blocked sites$/,$d' "$HOSTS_FILE" | replace_hosts
fi

launchctl bootout "system/$LABEL" 2>/dev/null
launchctl bootstrap system "$PLIST"

"$LIB_DIR/focus.sh"

echo "Installed: sites will be blocked at every boot."
