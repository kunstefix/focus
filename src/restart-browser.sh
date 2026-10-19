#!/bin/bash
# Restart the user's default browser so open tabs reconnect and hit the block.
# Browsers otherwise keep using their existing connections to blocked sites.
# Usage: restart-browser.sh <user>   (run as root, by focus.sh when a break ends)

user="$1"
[ -n "$user" ] || exit 0
uid="$(id -u "$user")" || exit 1

# Run in the user's GUI session, so Apple events and `open` reach their browser
as_user() {
    launchctl asuser "$uid" sudo -u "$user" "$@"
}

# "<bundle id><tab><name>" of the app that opens https links for this user
default_browser="$(as_user osascript -l JavaScript -e '
    ObjC.import("AppKit")
    const url = $.NSWorkspace.sharedWorkspace.URLForApplicationToOpenURL($.NSURL.URLWithString("https://example.com"))
    url.js ? $.NSBundle.bundleWithURL(url).bundleIdentifier.js + "\t" +
        $.NSFileManager.defaultManager.displayNameAtPath(url.path).js.replace(/\.app$/, "") : ""
')"
bundle_id="${default_browser%%$'\t'*}"
name="${default_browser#*$'\t'}"
[ -n "$bundle_id" ] || exit 0

browser_running() {
    [ "$(as_user osascript -e "application id \"$bundle_id\" is running")" = "true" ]
}

browser_running || exit 0

as_user osascript -e "display notification \"Break over. Restarting $name to close blocked sites.\" with title \"Focus\""
as_user osascript -e "quit app id \"$bundle_id\""

for _ in $(seq 30); do
    browser_running || break
    sleep 0.5
done

# Quit was cancelled, e.g. by a "Leave site?" dialog
browser_running && exit 0

# Chromium-based browsers can restore their tabs even when not set to
# "Continue where you left off". Others reopen tabs per their own settings.
case "$bundle_id" in
    com.google.Chrome* | com.brave.Browser* | com.microsoft.edgemac* | \
    com.vivaldi.Vivaldi* | com.operasoftware.Opera* | org.chromium.Chromium | \
    company.thebrowser.Browser)
        as_user open -b "$bundle_id" --args --restore-last-session ;;
    *)
        as_user open -b "$bundle_id" ;;
esac
