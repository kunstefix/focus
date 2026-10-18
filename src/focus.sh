#!/bin/bash
# Block every site in the sites file.
# Usage: focus.sh [sites-file]
# Without an argument it uses the file install.sh was given, else sites.txt in the repo root.

# Re-run as root (a cached sudo password is fine here)
[ "$EUID" -eq 0 ] || exec sudo "$0" "$@"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common.sh"

sites_file="$1"
if [ -z "$sites_file" ] && [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
    sites_file="$SITES_FILE"
fi
sites_file="${sites_file:-$(dirname "$SCRIPT_DIR")/sites.txt}"

if [ ! -f "$sites_file" ]; then
    echo "Error: File '$sites_file' not found!"
    echo "Create it with: cp sites.example.txt sites.txt"
    exit 1
fi

cancel_timer

# Keep everything else in /etc/hosts and append a fresh block of blocked sites
{
    hosts_without_block
    echo
    echo "$BLOCK_BEGIN"
    # Default IFS trims surrounding spaces; also drop a CRLF file's \r
    while read -r line || [ -n "$line" ]; do
        line="${line%$'\r'}"
        case "$line" in ''|\#*) continue ;; esac
        # Anything but a bare domain could smuggle other entries into /etc/hosts
        [[ "$line" =~ ^[A-Za-z0-9.-]+$ ]] || continue
        # Block IPv6 too, or the real AAAA record still resolves
        printf '127.0.0.1       www.%s\n' "$line"
        printf '127.0.0.1       %s\n' "$line"
        printf '::1             www.%s\n' "$line"
        printf '::1             %s\n' "$line"
    done < "$sites_file"
    echo "$BLOCK_END"
} | replace_hosts

flush_dns

echo "Focus on: sites are blocked."

exit 0
