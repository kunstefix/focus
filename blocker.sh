#!/bin/bash
# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Check if a file is provided as an argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

# Check if the file exists
if [ ! -f "$1" ]; then
    echo "Error: File '$1' not found!"
    exit 1
fi

base_hosts="$(dirname "$0")/hosts.base"

# Overwrite /etc/hosts with the base content followed by the blocked sites
{
    cat "$base_hosts"
    echo
    echo "# Blocked sites"
    while IFS= read -r line || [ -n "$line" ]; do
        [ -z "$line" ] && continue
        printf '127.0.0.1       www.%s\n' "$line"
        printf '127.0.0.1       %s\n' "$line"
    done < "$1"
} > /etc/hosts

echo "The /etc/hosts file has been updated."

exit 0
