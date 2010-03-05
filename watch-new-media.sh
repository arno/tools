#!/bin/bash
#
# Arnaud Guignard - 2010
#
# Watch /media directory and send a desktop notification when new media are
# mounted or unmounted.
#
# usage: watch-new-media.sh &
#
# dependencies: inotify-tools libnotify

inotifywait -m --exclude '/media/\.hal-mtab.*' -e create -e delete \
    --format '%e %f' /media | while read event media; do
        if [ "$event" = "CREATE,ISDIR" ]; then
            notify-send -i drive-harddisk "[mount] $media"
        elif [ "$event" = "DELETE,ISDIR" ]; then
            notify-send -i drive-harddisk "[umount] $media"
        fi
    done
