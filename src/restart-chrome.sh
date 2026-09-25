#!/bin/bash
# Restart Chrome as the given user so open tabs reconnect and hit the block.
# Chrome otherwise keeps using its existing connections to blocked sites.
# Usage: restart-chrome.sh <user>   (run as root, by the unfocus timer)

user="$1"
[ -n "$user" ] || exit 0
uid="$(id -u "$user")" || exit 1

# Run in the user's GUI session, so Apple events and `open` reach their Chrome
as_user() {
    launchctl asuser "$uid" sudo -u "$user" "$@"
}

chrome_running() {
    pgrep -x "Google Chrome" >/dev/null
}

chrome_running || exit 0

as_user osascript -e 'display notification "Break over. Restarting Chrome to close blocked sites." with title "Focus"'
as_user osascript -e 'quit app "Google Chrome"'

for _ in $(seq 30); do
    chrome_running || break
    sleep 0.5
done

# Quit was cancelled, e.g. by a "Leave site?" dialog
chrome_running && exit 0

# Restore the tabs even if Chrome isn't set to "Continue where you left off"
as_user open -a "Google Chrome" --args --restore-last-session
