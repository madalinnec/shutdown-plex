#!/bin/bash

# Define the Plex API URL and your Plex Token
PLEX_IP="127.0.0.1" # Replace with your Plex Server's IP if different
PLEX_TOKEN="your_plex_token" # Replace with your Plex Token
PLEX_API_URL="http://$PLEX_IP:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN"

# Function to check active Plex playback sessions
check_playback() {
  # Query Plex API to see if any media is being played
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
  # Check if Plex is running
  if ! systemctl is-active --quiet plexmediaserver; then
    echo "Plex Media Server is not running."
    exit 1
  fi

  # Check if any media is being played
  if check_playback; then
    echo "Playback detected. Shutdown aborted."
  else
    echo "No playback detected. Server will shut down in 20 minutes if no playback starts."

    # Wait for 20 minutes (1200 seconds)
    sleep 1200

    # Check again after 20 minutes
    if check_playback; then
      echo "Playback started within 20 minutes. Shutdown aborted."
    else
      echo "No playback after 20 minutes. Shutting down server."
      shutdown -h now
    fi
  fi

  # Wait 1 minute before checking again
  sleep 60
done
