#!/bin/bash

# Stop the shutdown-idle-plex service if running
sudo systemctl stop shutdown-idle-plex.service

# Disable the service so it doesn't start on boot
sudo systemctl disable shutdown-idle-plex.service

# Remove the service file from /etc/systemd/system/
sudo rm /etc/systemd/system/shutdown-idle-plex.service

# Remove the shutdown script from /usr/local/bin/
sudo rm /usr/local/bin/shutdown-idle-plex.sh

# Reload systemd to apply the changes
sudo systemctl daemon-reload

echo "Plex idle shutdown service has been uninstalled."

