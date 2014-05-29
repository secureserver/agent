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

if [ "$debug" = "true" ]
then
    set -x
fi

# Redirect stdout and stderr to logfile
exec >> $logfile 2>&1

# Logging function: logit ERROR "This is a test"
logit()
{
    level=$1
    message=$2
    date=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$date $level - $message"
}

machine_id=$(cat /var/lib/dbus/machine-id)
os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2)
os_codename=$(grep DISTRIB_CODENAME /etc/*release | cut -d= -f2)
hostname=$(hostname)

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

    request=$(printf '{"machine_id":"%s","os_name":"%s","os_release":"%s","os_codename":"%s","hostname":"%s","packages":[%s]}\n' \
                       "$machine_id" "$os_name" "$os_release" "$os_codename" "$hostname" "$packages")
}

function send_packages()
{
    request_check=$(echo -n "$request" | md5sum | cut -c 1-32)

    if [ -z "$last_request_check" ] || [ "$request_check" != "$last_request_check" ]
    then
        response=$(curl -X POST -iSL -w %{http_code} --silent \
                        --connect-timeout "$connect_timeout" \
                        --max-time "$max_time" \
                        -d "$request" "$service_endpoint" \
                        -H "Content-Type: application/json" \
                        --output /dev/null)

        if [ $response -eq 200 ]
        then
            logit INFO "Data sent successfully (Response code: $response)"
        else
            logit ERROR "Something went wrong (Response code: $response)"
        fi
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
