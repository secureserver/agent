#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================
endpoint="https://test.com"

os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2)
os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)

if hostname -f > /dev/null 2>&1
then 
    hostname=$(hostname -f)
else
    hostname=$(hostname)
fi

last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp)
current_time=$(date +%s)
if [ $(( $current_time - $last_update )) -ge 86400 ]
then
    apt-get -qq update
fi

IFS=$'\n'
pkg_upgrade=$(apt-get upgrade -s | grep ^Inst)
packages=()

for pkg in $pkg_upgrade
do
    name=$(echo "$pkg" | awk '{print $2}')
    version=$(echo "$pkg" | cut -d'[' -f2 | cut -d']' -f1)
    version_update=$(echo "$pkg" | awk -F'[()]' '{print $2}' | cut -d' ' -f1)

    packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s"},' \
                         "$name" "$version" "$version_update")
done

packages=$(sed 's/},$/}/g' <<< "$packages")

response=$(printf '{"os_name":"%s","os_release":"%s","os_codename":"%s","hostname":"%s","packages":[%s]}\n' \
                    "$os_name" "$os_release" "$os_codename" "$hostname" "$packages")

#curl -d "$response" -i "$endpoint"

echo "$response"
