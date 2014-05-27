#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================
trap '[ $pid ] && kill $pid' EXIT

args=("$@")

# Check the number of arguments
if [ ! "${#args[@]}" -eq 4 ]
then
    exit 2
fi

# Get config and log files path
for arg in "${!args[@]}"
do
    if [ "${args[$arg]}" = "-c" ]
    then
        configfile="${args[$arg+1]}"
    elif [ "${args[$arg]}" = "-l" ]
    then
        logfile="${args[$arg+1]}"
    fi
done

# Load the agent configuration file
[ -r "$configfile" ] && . "$configfile"

# Create log file if not exists
touch "$logfile"

os_name=$(awk -F ' release ' '{print $1}' /etc/redhat-release)
os_release=$(awk -F ' release ' '{print $2}' /etc/redhat-release | awk '{print $1}')
#os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)
hostname=$(hostname)

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

function send_packages()
{
    request_check=$(echo -n "$request" | md5sum | cut -c 1-32)

    if [ -z "$last_request_check" ] || [ "$request_check" != "$last_request_check" ]
    then
        curl --connect-timeout "$connect_timeout" --max-time "$max_time" \
             -d "$request" "$service_endpoint" > /dev/null 2>&1
        last_request_check="$request_check"
    fi
}

# Infinite loop which will keep the agent daemonized
while true
do
    check_packages
    send_packages
    sleep "$report_frequency" & pid=$!
    wait
done
