!! THE CHANGES ON THIS BRANCH WERE NOT VERIFIED AGAINST A SERVER RUNNING A STEAM CMD SERVER !!

For Ubuntu Server (verified on 22.04.5 LTS)

This sets up a service that verifies whether qbittorrent-nox is currently downloading or if plex is streaming. If not, the server will shut down in 20 minutes.

Make sure to modify the shutdown-idle-plex.sh script as it requires some details about Plex and qbittorrent. 

To get the Plex token, follow the instructions here:
https://support.plex.tv/articles/204059436-finding-an-authentication-token-x-plex-token/

Required:
jq - sudo apt install jq
