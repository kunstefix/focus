# Shared by the scripts in src/. Expects SCRIPT_DIR to be set.

HOSTS_FILE="/etc/hosts"
PID_FILE="/var/run/focus.pid"
DEADLINE_FILE="/var/run/focus.deadline"
# Root-only parents matter here: sudoers lets anyone run focus.sh as root
LIB_DIR="/Library/PrivilegedHelperTools/com.klemen.focus"
CONFIG_FILE="$LIB_DIR/config"
LOG_DIR="/var/db/focus"
LOG_FILE="$LOG_DIR/breaks.log"

# Focus only touches the lines between these markers in /etc/hosts
BLOCK_BEGIN="# BEGIN focus"
BLOCK_END="# END focus"

# Append a break event ("start <epoch> <deadline>" or "end <epoch>") to the log
log_event() {
    mkdir -p "$LOG_DIR"
    echo "$*" >> "$LOG_FILE"
}

# Kill a pending re-focus timer started by unfocus.sh, if any
cancel_timer() {
    if [ -f "$PID_FILE" ]; then
        kill "$(cat "$PID_FILE")" 2>/dev/null && log_event "end $(date +%s)"
        rm -f "$PID_FILE"
    fi
    rm -f "$DEADLINE_FILE"
}

# Print /etc/hosts without the focus block and without trailing blank lines
hosts_without_block() {
    awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" '
        $0 == b { skip = 1; next }
        $0 == e { skip = 0; next }
        skip { next }
        /^[[:space:]]*$/ { blank = blank $0 "\n"; next }
        { printf "%s", blank; blank = ""; print }
    ' "$HOSTS_FILE"
}

# Replace /etc/hosts with stdin. Goes through a temp file because the input
# is usually read from /etc/hosts itself; `cat >` keeps its owner and mode.
replace_hosts() {
    local tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    cat "$tmp" > "$HOSTS_FILE"
    rm -f "$tmp"
}

flush_dns() {
    dscacheutil -flushcache 2>/dev/null
    killall -HUP mDNSResponder 2>/dev/null
}
