#!/usr/bin/env bash
#===============================================================================
#
# SecureServer
#
#===============================================================================
args=("$@")

# check number of arguments
if [ ! "${#args[@]}" -eq 2 ]
then
    echo -e "\nUSAGE: secureserver-config --set key=value\n"
    exit 1
fi

# get option, key and value parameters
option=$1
key=$(echo $2 | cut -d= -f1)
value=$(echo $2 | cut -d= -f2 -s)

if [ "$option" == "--set" ]
then
    if [ "$key" == "api_key" ]
    then
        [ -r /etc/secureserver/agent.config ] && \
        sed -i "s/api_key=.*/api_key=${value}/g" /etc/secureserver/agent.config
    else
        echo -e "\nKey: $key not found!\n"
        exit 1
    fi
else
    echo -e "\nOption: $option not found!\n"
    exit 1
fi
