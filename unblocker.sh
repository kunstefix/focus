#!/bin/bash

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

base_hosts="$(dirname "$0")/hosts.base"

# Overwrite /etc/hosts with the base content
cat "$base_hosts" > /etc/hosts

echo "The /etc/hosts file has been updated."

exit 0
