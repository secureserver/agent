#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================
set -e

os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2)
hostname=$(hostname)

IFS=$'\n'
pkg_upgrade=$(apt-get upgrade -s | grep ^Inst) || true

if [ ! -z "$pkg_upgrade" ]
then
    pkg_number=$(echo "$pkg_upgrade" | wc -l)
fi
packages=()

n=1
for pkg in $pkg_upgrade
do
    name=$(echo $pkg | cut -d' ' -f2)
    version=$(echo $pkg | cut -d'[' -f2 | cut -d']' -f1)
    version_update=$(echo $pkg | awk -F'[()]' '{print $2}' | cut -d' ' -f1)

    if [ $n -ne $pkg_number ]
    then
        packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s"},' \
                           "$name" "$version" "$version_update")
    else
        packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s"}' \
                           "$name" "$version" "$version_update")
    fi
    n=$(( n+1 ))
done

printf '{"os_name":"%s","os_release":"%s","hostname":"%s","packages":[%s]}\n' \
       "$os_name" "$os_release" "$hostname" "$packages"
