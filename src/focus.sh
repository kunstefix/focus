#!/bin/bash
# Block every site in the sites file (default: sites.txt in the repo root).
# Usage: focus.sh [sites-file]

# Re-run as root (a cached sudo password is fine here)
[ "$EUID" -eq 0 ] || exec sudo "$0" "$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

sites_file="${1:-$(dirname "$SCRIPT_DIR")/sites.txt}"
if [ ! -f "$sites_file" ]; then
    echo "Error: File '$sites_file' not found!"
    echo "Create it with: cp sites.example.txt sites.txt"
    exit 1
fi

cancel_timer

# Overwrite /etc/hosts with the base content followed by the blocked sites
{
    cat "$BASE_HOSTS"
    echo
    echo "# Blocked sites"
    while IFS= read -r line || [ -n "$line" ]; do
        case "$line" in ''|\#*) continue ;; esac
        printf '127.0.0.1       www.%s\n' "$line"
        printf '127.0.0.1       %s\n' "$line"
    done < "$sites_file"
} > "$HOSTS_FILE"

flush_dns

echo "Focus on: sites are blocked."

exit 0
