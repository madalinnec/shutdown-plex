#!/bin/bash

PLEX_IP="127.0.0.1"
PLEX_TOKEN="your_plex_token"

QBITTORRENT_IP="127.0.0.1"
QBITTORRENT_PORT="8080"
QBITTORRENT_API_URL="http://$QBITTORRENT_IP:$QBITTORRENT_PORT/api/v2/transfer/info"

# Define the maximum download speed (in bytes/second). 1 Mbps = 125000 Bytes/s.
MAX_DOWNLOAD_SPEED=125000

video_is_playing() {
  local plex_api_url="http://$PLEX_IP:32400/status/sessions?X-Plex-Token=$PLEX_TOKEN"
  local playback=$(curl -s "$plex_api_url" | grep -o '<Player.*state="playing"')
  if [ -n "$playback" ]; then
    echo "Videos are playing on Plex."
    return 0
  else
    echo "No videos are playing on Plex."
    return 1
  fi
}

qbittorrent_is_downloading() {
  local download_speed=$(curl -s "$QBITTORRENT_API_URL" | jq '.dl_info_speed')

  if [ "$download_speed" -gt "$MAX_DOWNLOAD_SPEED" ]; then
    echo "qBittorrent is downloading at a speed greater than 1 Mbps."
    return 0
  else
    echo "qBittorrent is downloading at less than 1 Mbps."
    return 1
  fi
}

MINUTES=0
while true; do
  if ! systemctl is-active --quiet plexmediaserver; then
    echo "Plex Media Server is not running."
    exit 1
  fi

  if ! systemctl is-active --quiet qbittorrent-nox; then
    echo "qBittorrent-nox is not running."
    exit 1
  fi

  sleep 180

  if video_is_playing || qbittorrent_is_downloading; then
    echo "Plex is playing or qBittorrent is downloading."
    MINUTES=0
  else
    MINUTES=$((MINUTES + 3))
    echo "No playback on Plex and qBittorrent download is below 1 Mbps for about $MINUTES minutes. Server will shut down after 21 minutes"
    if [ "$MINUTES" -gt 20 ]; then
      echo "No playback on Plex and no significant download on qBittorrent after 21 minutes. Shutting down server."
      shutdown -h now
    fi
  fi

  sleep 180
done
