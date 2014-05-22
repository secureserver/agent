#!/bin/sh
set -e

bin_path="#{destdir}"
bins="secureserver-agent secureserver-config"
user="secureserver"
group="secureserver"

if [ "$1" != "upgrade" ]
then
    service secureserver-agent stop || true
    for bin in $bins; do
        update-alternatives --remove "$bin" "$bin_path"/"$bin"
    done
    echo "Removing user '$user' ..."
    userdel "$user" || true
fi

exit 0
