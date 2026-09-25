#!/bin/bash
# Install a LaunchDaemon that runs focus.sh at every boot, then focus immediately.

LIB_DIR="/usr/local/lib/focus"
LABEL="com.klemen.focus"
PLIST="/Library/LaunchDaemons/$LABEL.plist"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SITES_FILE="$REPO_DIR/sites.txt"

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

if [ ! -f "$SITES_FILE" ]; then
    echo "Error: File '$SITES_FILE' not found!"
    echo "Create it with: cp sites.example.txt sites.txt"
    exit 1
fi

# The daemon runs as root, so it runs root-owned copies rather than the
# user-writable scripts in the repo. The sites list is still read from the repo.
mkdir -p "$LIB_DIR"
cp "$SCRIPT_DIR/focus.sh" "$SCRIPT_DIR/common.sh" "$SCRIPT_DIR/hosts.base" "$LIB_DIR/"
chown -R root:wheel "$LIB_DIR"
chmod 755 "$LIB_DIR" "$LIB_DIR/focus.sh"
chmod 644 "$LIB_DIR/common.sh" "$LIB_DIR/hosts.base"

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
        <string>$SITES_FILE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST
chown root:wheel "$PLIST"
chmod 644 "$PLIST"

launchctl bootout "system/$LABEL" 2>/dev/null
launchctl bootstrap system "$PLIST"

"$LIB_DIR/focus.sh" "$SITES_FILE"

echo "Installed: sites will be blocked at every boot."
