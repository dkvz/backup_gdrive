#!/bin/bash

BACKUP_SOURCES="/srv/
/etc/nginx/
/etc/nftables.conf
/etc/postfix/
/etc/systemd/system/
/home/mailuser/"

# <RCLONE_REMOTE>:<BACKUP_DIR>
# No trailing slash!
RCLONE_DEST="onedrive:/vps"

for s in $BACKUP_SOURCES; do
  if ! rclone sync "$s" "${RCLONE_DEST}/${s}"
  then
    echo "backup sync error for ${s}"
  fi
done
