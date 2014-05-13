#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================

# Load the agent configuration file
[ -r /etc/secureserver/agent.config ] && . /etc/secureserver/agent.config

os_name=$(awk -F ' release ' '{print $1}' /etc/redhat-release)
os_release=$(awk -F ' release ' '{print $2}' /etc/redhat-release | awk '{print $1}')
#os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)

# Get the hostname or fqdn if exists
if hostname -f > /dev/null 2>&1
then
    hostname=$(hostname -f)
else
    hostname=$(hostname)
fi

function check_packages()
{
    IFS=$'\n'
    pkg_upgrade=$(yum list updates -q | grep -v "Updated Packages")
    pkg_installed=$(rpm -qa)
    packages=()

    for pkg in $pkg_upgrade
    do
        name=$(echo "$pkg" | cut -d'.' -f1 )
        version=$(echo "$pkg_installed" | grep "^${name}-[0-9]" | sed -e "s/^${name}-//g" -e "s/.[^.]*$//g")
        version_update=$(echo "$pkg" | awk '{print $2}')
        repo=$(echo "$pkg" | awk '{print $3}')

        packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s","repo":"%s"},' \
                             "$name" "$version" "$version_update" "$repo")
    done

    packages=$(sed 's/},$/}/g' <<< "$packages")

    request=$(printf '{"os_name":"%s","os_release":"%s","os_codename":"%s","hostname":"%s","packages":[%s]}\n' \
                        "$os_name" "$os_release" "$os_codename" "$hostname" "$packages")
}

# Infinite loop which will keep the agent daemonized
while true
do
    check_packages
    request_check=$(echo -n "$request" | md5sum | cut -c 1-32)

    if [ -z "$previous_request_check" ] || [ "$request_check" != "$previous_request_check" ]
    then
        curl --connect-timeout "$connect_timeout" --max-time "$max_time" \
             -d "$request" -i "$service_endpoint" > /dev/null 2>&1
        previous_request_check="$request_check"
    fi
    sleep "$report_frequency"
done

