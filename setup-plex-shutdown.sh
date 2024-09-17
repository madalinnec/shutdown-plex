#!/bin/bash

# Define the script and service file names
SCRIPT_NAME="shutdown-idle-plex.sh"
SERVICE_NAME="shutdown-idle-plex.service"

# Get the directory of the currently running script (resolves both relative and absolute paths)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define full paths for script and service files
SCRIPT_FILE="$SCRIPT_DIR/$SCRIPT_NAME"
SERVICE_FILE="$SCRIPT_DIR/$SERVICE_NAME"

# Check if shutdown-idle-plex.sh exists
if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: $SCRIPT_NAME not found in $SCRIPT_DIR"
    exit 1
fi

# Check if shutdown-idle-plex.service exists
if [ ! -f "$SERVICE_FILE" ]; then
    echo "Error: $SERVICE_NAME not found in $SCRIPT_DIR"
    exit 1
fi

# Install the service and script
echo "Installing shutdown-idle-plex service and script..."

# Copy the script to /usr/local/bin
sudo cp "$SCRIPT_FILE" /usr/local/bin/
sudo chmod +x /usr/local/bin/$SCRIPT_NAME

# Copy the service file to systemd
sudo cp "$SERVICE_FILE" /etc/systemd/system/

# Reload systemd, enable, and start the service
sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

echo "shutdown-idle-plex service installed and started successfully."
