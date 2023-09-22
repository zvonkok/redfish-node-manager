#!/bin/bash 

set -e 
set -x

REDFISH_IP=""
REDFISH_USER="$1"
REDFISH_PASSWD="$2"

get_redfish_ip () {
        local table42
        local redfish_ip_format

        table42=$(dmidecode -t 42)
        redfish_ip_format=$(echo "$table42" | grep "Redfish Service IP Address Format" | cut -d':' -f2 | tr -d '[:space:]')
        REDFISH_IP=$(echo "$table42" | grep "${redfish_ip_format} Redfish Service Address" | cut -d':' -f2 | tr -d '[:space:]')
        # GENOA 10.153.145.96
        REDFISH_IP=10.153.145.96
}


get_redfish_ip


curl -k https://"${REDFISH_IP}":443/redfish/v1 | jq . 

#curl -k https://"${REDFISH_IP}"/redfish/v1/Systems/1/Bios -u  "${REDFISH_USER}:${REDFISH_PASSWD}"  | jq .