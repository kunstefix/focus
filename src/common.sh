# Shared by focus.sh and unfocus.sh. Expects SCRIPT_DIR to be set.

HOSTS_FILE="/etc/hosts"
PID_FILE="/var/run/focus.pid"
BASE_HOSTS="$SCRIPT_DIR/hosts.base"

# Kill a pending re-focus timer started by unfocus.sh, if any
cancel_timer() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null
        rm -f "$PID_FILE"
    fi
}

flush_dns() {
    dscacheutil -flushcache 2>/dev/null
    killall -HUP mDNSResponder 2>/dev/null
}
