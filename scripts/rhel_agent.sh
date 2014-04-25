#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================

os_name=$(awk -F ' release ' '{print $1}' /etc/redhat-release)
os_release=$(awk -F ' release ' '{print $2}' /etc/redhat-release | awk '{print $1}')
#os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)
hostname=$(hostname)

IFS=$'\n'
pkg_upgrade=$(yum list updates -q | grep -v "Updated Packages") || true
pkg_installed=$(rpm -qa)
packages=()

for pkg in $pkg_upgrade
do
    name=$(echo $pkg | cut -d'.' -f1 )
    version=$(echo "${pkg_installed}" | grep "^${name}-[0-9]" | sed "s/^${name}-//g" | sed 's/.[^.]*$//g')
    version_update=$(echo ${pkg} | awk '{print $2}')

    packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s"},' \
                         "$name" "$version" "$version_update")
done

packages=$(sed 's/},$/}/g' <<< $packages)

printf '{"os_name":"%s","os_release":"%s","os_codename":"%s","hostname":"%s","packages":[%s]}\n' \
         "$os_name" "$os_release" "$os_codename" "$hostname" "$packages"
