#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================
args=("$@")

# check if config file is readable
[ ! -r /etc/secureserver/agent.config ] && exit 1

# get keys from agent config file
config_keys=$(grep '^[a-z].*' /etc/secureserver/agent.config | cut -d= -f1)

# check number of arguments
if [ ! "${#args[@]}" -eq 2 ]
then
    echo -e "\nUSAGE: secureserver-config --set key=value"
    echo -e "\nKeys from agent.config:"
    for key in $config_keys
    do
        echo " ${key}"
    done
    echo ""
    exit 1
fi

# get option, key and value parameters
option="$1"
key=$(echo "$2" | cut -d= -f1)
value=$(echo "$2" | cut -d= -f2 -s)

if [ "$option" == "--set" ]
then
    if [ ! "$(echo "$config_keys" | grep -cwm1 "$key")" -eq 0 ]
    then
        echo -e "\nConfig modified: ${key}=${value}\n"
        sed -i "s|${key}=.*|${key}=${value}|g" /etc/secureserver/agent.config
    else
        echo -e "\nKey: $key not found!\n"
        exit 1
    fi
else
    echo -e "\nOption: $option not found!\n"
    exit 1
fi