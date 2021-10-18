#!/bin/sh

mount_location = ""
share_location = ""
username = ""
password = ""

sudo mount -t cifs "$share_location" \
    -o username="$username",password="$password",rw,file_mode=0777,dir_mode=0777 \
    "$mount_location"