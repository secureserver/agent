#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================

# Load the agent configuration file
[ -r /etc/secureserver/agent.config ] && . /etc/secureserver/agent.config

os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2)
os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)

# Get the hostname or fqdn if exists
if hostname -f > /dev/null 2>&1
then
    hostname=$(hostname -f)
else
    hostname=$(hostname)
fi

function check_packages()
{
    #last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp)
    #current_time=$(date +%s)
    #if [ $(( current_time - last_update )) -ge 86400 ]
    #then
        #apt-get -qq update
    #fi

    IFS=$'\n'
    pkg_upgrade=$(apt-get upgrade -s | grep ^Inst)
    packages=()

    for pkg in $pkg_upgrade
    do
        name=$(echo "$pkg" | awk '{print $2}')
        version=$(echo "$pkg" | cut -d'[' -f2 | cut -d']' -f1)
        version_update=$(echo "$pkg" | awk -F '[()]' '{print $2}' | cut -d' ' -f1)
        repo=$(echo "$pkg" | awk '{print $5}')

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

