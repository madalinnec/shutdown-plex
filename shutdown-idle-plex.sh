#!/bin/bash

# Define Plex and qBittorrent variables
PLEX_IP="127.0.0.1" # Plex server IP
PLEX_TOKEN="your_plex_token" # Plex token

QBITTORRENT_IP="127.0.0.1" # qBittorrent IP (if it's running locally)
QBITTORRENT_PORT="8080" # Default qBittorrent Web UI port
QBITTORRENT_USER="your_qbittorrent_username" # qBittorrent Web UI username
QBITTORRENT_PASSWORD="your_qbittorrent_password" # qBittorrent Web UI password
QBITTORRENT_API_URL="http://$QBITTORRENT_IP:$QBITTORRENT_PORT/api/v2/transfer/info"

# Define the maximum download speed (in bytes/second). 1 Mbps = 125000 Bytes/s.
MAX_DOWNLOAD_SPEED=125000

# Temporary file to store cookies
COOKIE_FILE=$(mktemp)

# Function to check active Plex playback sessions
check_playback() {
  local plex_api_url="http://$PLEX_IP:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN"
  local playback=$(curl -s "$plex_api_url" | grep -o '<Player.*state="playing"')
  if [ -n "$playback" ]; then
    echo "A video is currently being played on Plex."
    return 0
  else
    echo "No video is currently being played on Plex."
    return 1
  fi
}

# Function to authenticate with qBittorrent Web UI and store session cookies
authenticate_qbittorrent() {
  # Perform login and store session cookies in the COOKIE_FILE
  curl -s -c "$COOKIE_FILE" -X POST -d "username=$QBITTORRENT_USER&password=$QBITTORRENT_PASSWORD" \
    "http://$QBITTORRENT_IP:$QBITTORRENT_PORT/api/v2/auth/login" > /dev/null

  # Check if login was successful (the API returns an empty body on success)
  if grep -q "SID" "$COOKIE_FILE"; then
    echo "qBittorrent login successful."
    return 0
  else
    echo "Failed to log into qBittorrent Web UI."
    return 1
  fi
}

# Function to check qBittorrent download speed
check_qbittorrent_download_speed() {
  # Re-authenticate before checking download speed, in case the session has expired
  if ! authenticate_qbittorrent; then
    return 1
  fi

  # Query qBittorrent download speed using stored session cookie
  local download_speed=$(curl -s -b "$COOKIE_FILE" "$QBITTORRENT_API_URL" | jq '.dl_info_speed')

  if [ "$download_speed" -gt "$MAX_DOWNLOAD_SPEED" ]; then
    echo "qBittorrent is downloading at a speed greater than 1 Mbps."
    return 0
  else
    echo "qBittorrent is downloading at less than 1 Mbps."
    return 1
  fi
}

# Infinite loop to check both Plex playback status and qBittorrent download speed every minute
while true; do
  # Check if Plex Media Server is running
  if ! systemctl is-active --quiet plexmediaserver; then
    echo "Plex Media Server is not running."
    exit 1
  fi

  # Check if qBittorrent is running
  if ! systemctl is-active --quiet qbittorrent-nox; then
    echo "qBittorrent-nox is not running."
    exit 1
  fi

  # Check if any media is being played on Plex and if qBittorrent is downloading at more than 1 Mbps
  if check_playback && check_qbittorrent_download_speed; then
    echo "Either Plex is playing or qBittorrent is downloading. Shutdown aborted."
  else
    echo "No playback on Plex and qBittorrent download is below 1 Mbps. Server will shut down in 20 minutes if no change."

    # Wait for 20 minutes (1200 seconds)
    sleep 1200

    # Check again after 20 minutes
    if check_playback && check_qbittorrent_download_speed; then
      echo "Conditions changed. Shutdown aborted."
    else
      echo "No playback on Plex and no significant download on qBittorrent after 20 minutes. Shutting down server."
      shutdown -h now
    fi
  fi

  # Wait 1 minute before checking again
  sleep 60
done

# Cleanup: remove the temporary cookie file
trap "rm -f $COOKIE_FILE" EXIT
