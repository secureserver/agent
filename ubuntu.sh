#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================
set -e

os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2)
os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)
hostname=$(hostname)

IFS=$'\n'
pkg_upgrade=$(apt-get upgrade -s | grep ^Inst) || true
packages=()

for pkg in $pkg_upgrade
do
    name=$(echo $pkg | cut -d' ' -f2)
    version=$(echo $pkg | cut -d'[' -f2 | cut -d']' -f1)
    version_update=$(echo $pkg | awk -F'[()]' '{print $2}' | cut -d' ' -f1)

    packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s"},' \
                         "$name" "$version" "$version_update")
done

packages=$(sed 's/},$/}/g' <<< $packages)

printf '{"os_name":"%s","os_release":"%s","os_codename":"%s","hostname":"%s","packages":[%s]}\n' \
         "$os_name" "$os_release" "$os_codename" "$hostname" "$packages"
