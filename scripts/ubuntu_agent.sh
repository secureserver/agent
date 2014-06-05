#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================
trap '[ $pid ] && kill $pid' EXIT

set -o pipefail

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

machine_id=$(cat /var/lib/dbus/machine-id)
os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2 2>/dev/null \
               || cat /etc/issue | awk '{print $1}')
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2 2>/dev/null \
                  || cat /etc/issue | awk '{print $3}')
hostname=$(hostname)

# Logging function: logit ERROR "This is a test"
function logit()
{
    level=$1
    message=$2
    date=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$date $level - $message"
}

function check_update()
{
    update_success_stamp=/var/lib/apt/periodic/update-success-stamp
 
    if [ ! -f "$update_success_stamp" ]
    then
        logit WARNING "Could not check last update time. Run as root: apt-get update"
    else
        current_time=$(date +%s)
        last_update=$(stat -c %Y "$update_success_stamp")
        if [ $(( current_time - last_update )) -ge 86400 ]
        then
            logit WARNING "Last update success stamp older than 24h. Run as root: apt-get update"
        fi
    fi
}

function check_packages()
{
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

    request=$(printf '{"machine_id":"%s","report_frequency":"%s","os_name":"%s","os_release":"%s","hostname":"%s","packages":[%s]}\n' \
                       "$machine_id" "$report_frequency" "$os_name" "$os_release" "$hostname" "$packages")
}

function send()
{
    curl -X POST -iSL -w %{http_code} --silent \
                 --connect-timeout "$connect_timeout" \
                 --max-time "$max_time" \
                 -d "$1" "$service_endpoint" \
                 -H "Content-Type: application/json" \
                 --output /dev/null
}

function send_ping()
{
    ping_request=$(printf '{"machine_id":"%s","report_frequency":"%s"}\n' "$machine_id" "$report_frequency")
    response=$(send $ping_request)

    if [ $response -eq 200 ]
    then
        logit INFO "Ping sent successfully"
    else
        logit ERROR "Something went wrong while sending ping (Response code: $response)"
    fi
}

function send_packages()
{
    request_check=$(echo -n "$request" | md5sum | cut -c 1-32)

    if [ -z "$last_request_check" ] || [ "$request_check" != "$last_request_check" ]
    then
        response=$(send $request)

        if [ $response -eq 200 ]
        then
            logit INFO "Packages data sent successfully"
            last_request_check="$request_check"
        else
            logit ERROR "Something went wrong while sending packages data (Response code: $response)"
        fi
    else
        send_ping
    fi
}

# Infinite loop which will keep the agent daemonized
while true
do
    check_update
    check_packages
    send_packages
    sleep "$report_frequency" & pid=$!
    wait
done
