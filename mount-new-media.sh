#!/bin/bash
#
# Arnaud Guignard - 2010
#
# Watch new inserted media thanks to udisks(7), mount them and send a desktop
# notification.
#
# usage: mount-new-media.sh &
#
# dependencies: libnotify-bin udisks

udisks --monitor | while read line; do
    if echo "$line" | egrep '^added:.*sd[a-z][0-9]$' >/dev/null; then
        dev=$(echo "$line" | cut -d/ -f6)
        media=$(udisks --mount /dev/$dev | awk '{ print $4 }')
        notify-send -i drive-harddisk "[mount] $media"
    fi
done

