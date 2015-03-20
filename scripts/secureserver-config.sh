#!/usr/bin/env bash
#===============================================================================
#
# MAINTAINER: secureserver.io
#
#===============================================================================

set -eo pipefail

readonly configfile="/etc/secureserver/agent.config"
args=("$@")

# Check if config file is readable
[[ ! -r "$configfile" ]] && exit 1

# Get keys from agent config file
config_keys=$(grep '^[a-z].*' "$configfile" | cut -d= -f1)

# Check the number of arguments
if [[ ! "${#args[@]}" -eq 2 ]]; then
  echo -e "\nUSAGE: secureserver-config --set key=value"
  echo -e "\nKeys from agent.config:"
  for key in $config_keys; do
    echo " ${key}"
  done
  echo ""
  exit 2
fi

# Get option, key and value parameters
option="$1"
key=$(echo "$2" | cut -d= -f1)
value=$(echo "$2" | cut -d= -f2 -s)

if [[ "$option" == "--set" ]]; then
  if [[ ! "$(echo "$config_keys" | grep -cwm1 "$key")" -eq 0 ]]; then
    sed -i "s|${key}=.*|${key}=${value}|g" "$configfile" 2>/dev/null
    if [[ $? -eq 0 ]]; then
      echo -e "\nConfig modified: ${key}=${value}\n"
    else
      echo -e "\nERROR: Could not modify configuration. Are you sudo/root?\n"
    fi
  else
    echo -e "\nKey: $key not found!\n"
  fi
else
  echo -e "\nOption: $option not found!\n"
fi
