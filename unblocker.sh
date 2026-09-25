#!/bin/bash

# Check if the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

# Define the new content for /etc/hosts
new_hosts_content="##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1       localhost
127.0.0.1       wundertax.api
127.0.0.1       assets.wtx elster.wtx jsonizer.wtx submission.wtx usermandate.wtx usermandate-2.wtx app.wtx merger.wtx germantaxes--de.local.wundertax.green germantaxes--de.local.wundertax.green studentensteuererklaerung--de.local.wundertax.green

255.255.255.255 broadcasthost
::1             localhost
# Added by Docker Desktop
# To allow the same kube context to work on the host and the container:
127.0.0.1 kubernetes.docker.internal
# End of section"

# Overwrite /etc/hosts with the new content
echo "$new_hosts_content" > /etc/hosts

echo "The /etc/hosts file has been updated."

exit 0