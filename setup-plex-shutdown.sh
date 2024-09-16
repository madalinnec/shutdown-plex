#!/bin/bash

# Create the shutdown-idle-plex.sh script file
cat <<'EOF' | sudo tee /usr/local/bin/shutdown-idle-plex.sh > /dev/null
#!/bin/bash

# Define the Plex API URL and your Plex Token
PLEX_IP="127.0.0.1"
PLEX_TOKEN="your_plex_token"
PLEX_API_URL="http://$PLEX_IP:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN"

# Function to check active Plex playback sessions
check_playback() {
  playback=$(curl -s "$PLEX_API_URL" | grep -o '<Player.*state="playing"')
  if [ -n "$playback" ]; then
    echo "A video is currently being played."
    return 0
  else
    echo "No video is currently being played."
    return 1
  fi
}

# Infinite loop to check Plex playback status every minute
while true; do
  if ! systemctl is-active --quiet plexmediaserver; then
    echo "Plex Media Server is not running."
    exit 1
  fi

  if check_playback; then
    echo "Playback detected. Shutdown aborted."
  else
    echo "No playback detected. Server will shut down in 20 minutes if no playback starts."
    sleep 1200
    if check_playback; then
      echo "Playback started within 20 minutes. Shutdown aborted."
    else
      echo "No playback after 20 minutes. Shutting down server."
      shutdown -h now
    fi
  fi
  sleep 60
done
EOF

# Make the shutdown script executable
sudo chmod +x /usr/local/bin/shutdown-idle-plex.sh

# Create the shutdown-idle-plex.service file
cat <<EOF | sudo tee /etc/systemd/system/shutdown-idle-plex.service > /dev/null
[Unit]
Description=Shutdown Idle Plex Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/shutdown-idle-plex.sh
User=root
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable and start the shutdown-idle-plex service
sudo systemctl enable shutdown-idle-plex.service
sudo systemctl start shutdown-idle-plex.service

echo "Plex idle shutdown service installed and started."

