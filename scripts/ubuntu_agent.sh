#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================
trap '[ $pid ] && kill $pid' EXIT

set -eo pipefail

args=("$@")

# Check the number of arguments
if [[ ! "${#args[@]}" -eq 4 ]]; then
  exit 2
fi

# Get config and log files path
for arg in "${!args[@]}"; do
  if [[ "${args[$arg]}" == "-c" ]]; then
    configfile="${args[$arg+1]}"
  elif [[ "${args[$arg]}" == "-l" ]]; then
    logfile="${args[$arg+1]}"
  fi
done

# Load the agent configuration file
[[ -r "$configfile" ]] && . "$configfile"

# Create log file if not exists
touch "$logfile"

if [[ "$debug" = "true" ]]; then
  set -x
fi

# Redirect stdout and stderr to logfile
exec >> $logfile 2>&1

machine_id=$(cat /var/lib/dbus/machine-id)
os_name=$(grep DISTRIB_ID /etc/*release | cut -d= -f2 2>/dev/null \
               || awk '{print $1}' /etc/issue)
os_release=$(grep DISTRIB_RELEASE /etc/*release | cut -d= -f2 2>/dev/null \
                  || awk '{print $3}' /etc/issue)
hostname=$(hostname)

# Logging function: logit ERROR "This is a test"
logit() {
  local level="$1"
  local message="$2"
  local date=$(date "+%Y-%m-%d %H:%M:%S")

  echo "$date $level - $message"
}

check_update() {
  update_success_stamp=/var/cache/apt
 
  if [[ ! -d "$update_success_stamp" ]]; then
    logit WARNING "Could not check last update time. Run as root: apt-get update"
  else
    local current_time=$(date +%s)
    local last_update=$(stat -c %Y "$update_success_stamp")
    if [[ $(( current_time - last_update )) -ge 86400 ]]; then
      logit WARNING "Last update success stamp older than 24h. Run as root: apt-get update"
    fi
  fi
}

check_packages() {
  IFS=$'\n'
  local pkg_upgrade=$(apt-get upgrade -s | grep ^Inst)
  local packages=()

  for pkg in $pkg_upgrade; do
    local name=$(echo "$pkg" | awk '{print $2}')
    local version=$(echo "$pkg" | cut -d'[' -f2 | cut -d']' -f1)
    local version_update=$(echo "$pkg" | awk -F '[()]' '{print $2}' | cut -d' ' -f1)
    local repo=$(echo "$pkg" | awk '{print $5}')

    packages+=$(printf '{"name":"%s","version":"%s","version_update":"%s","repo":"%s"},' \
                         "$name" "$version" "$version_update" "$repo")
  done

  packages=$(sed 's/},$/}/g' <<< "$packages")

  request=$(printf '{"machine_id":"%s","report_frequency":"%s","os_name":"%s","os_release":"%s","hostname":"%s","packages":[%s]}\n' \
                     "$machine_id" "$report_frequency" "$os_name" "$os_release" "$hostname" "$packages")
}

send() {
  local data="$1"

  curl -X POST -iSL -w %{http_code} --silent \
       --connect-timeout "$connect_timeout" \
       --max-time "$max_time" \
       -d "$data" "$service_endpoint" \
       -H "Content-Type: application/json" \
       --output /dev/null
}

send_ping() {
  local ping_request=$(printf '{"machine_id":"%s","report_frequency":"%s"}\n' "$machine_id" "$report_frequency")
  local response=$(send "$ping_request")

  if [[ "$response" -eq 200 ]]; then
    logit INFO "Ping sent successfully"
  else
    logit ERROR "Something went wrong while sending ping (Response code: ${response})"
  fi
}

send_packages() {
  local request_check=$(echo -n "$request" | md5sum | cut -c 1-32)

  if [[ -z "$last_request_check" ]] || [[ "$request_check" != "$last_request_check" ]]; then
    local response=$(send "$request")

    if [[ "$response" -eq 200 ]]; then
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
while true; do
  check_update
  check_packages
  send_packages
  sleep "$report_frequency" & pid=$!
  wait
done
