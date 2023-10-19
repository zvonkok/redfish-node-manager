#!/bin/bash 

#set -e 
#set -x


REDFISH_USER="$1"
REDFISH_PASSWD="$2"
REDFISH_IP="$3" # override

redfish_ipv4_ip=""
redfish_ipv6_ip=""

get_redfish_ip () {
        local table42
        local redfish_ip_format

        table42=$(sudo dmidecode -t 42)

        echo "$table42" | csplit --digits=1 --quiet --prefix=redfish_host_interface_ - '/^$/+1' '{*}'
        
        # do not care just the header
        rm -f redfish_host_interface_0 

        for i in redfish_host_interface_*; do
                redfish_host_interface=$(cat "$i")
                redfish_protocol=$(echo "$redfish_host_interface" | grep -o "Redfish over IP")
                if [ -z "$redfish_protocol" ]; then
                        rm -f "$i"
                        continue
                fi
                redfish_ip_format=$(echo "$redfish_host_interface" | grep "Redfish Service IP Address Format" | cut -d':' -f2 | tr -d '[:space:]')
                redfish_ip=$(echo "$redfish_host_interface" | grep "${redfish_ip_format} Redfish Service Address" | cut -d':' -f2 | tr -d '[:space:]')

                # depending on the ip format set the ip addresss
                if [ "$redfish_ip_format" == "IPv4" ]; then
                        redfish_ipv4_ip="$redfish_ip"
                elif [ "$redfish_ip_format" == "IPv6" ]; then
                        redfish_ipv6_ip="$redfish_ip"
                fi
        
        done

        echo IPv4 Redfish IP: "$redfish_ipv4_ip"
        echo IPv6 Redfish IP: "$redfish_ipv6_ip"
}

discover_bios_vendor () {
        local table0
        local bios_vendor

        table0=$(sudo dmidecode -t 0)

        bios_vendor=$(echo "$table0" | grep "Vendor:" | cut -d':' -f2 | tr -d '[:space:]')

        echo "BIOS Vendor: $bios_vendor"
}


get_redfish_ip
discover_bios_vendor

if [ -n "${REDFISH_IP}" ]; then
        redfish_ipv4_ip=${REDFISH_IP}
fi


echo "Redfish Vendor: $redfish_vendor"

lenovo_bios_snp_settings=$(cat <<EOF 
{
        "Attributes": {
                "Memory_SMEE": "Enabled",
                "Memory_SEV_ESASIDSpaceLimit": 100,
                "Processors_SNPMemoryRMPTableCoverage": "Enabled",
                "Processors_SEV_SNPSupport": "Enabled"
        }
}
EOF
)

Intel TDX Key Split ? 

supermicro_tdx_settings=$(cat <<EOF 
{
        "Attributes": {
                "VolatileMemoryMode#F302": "1LM",
                "MemoryEncryption(TME)#3C36": "Enabled",                
                "TotalMemoryEncryption(TME)Bypass#3C37": "Auto",
                "TotalMemoryEncryptionMulti-Tenant(TME-MT)#F31B": "Enabled",
                "MemoryIntegrity#F31A": "Disabled",
                "TDXSecureArbitrationModeLoader(SEAMLoader)#3C39": "Enabled",
                "TrustDomainExtension(TDX)#3C38": "Enabled",
                "LimitCPUPAto46Bits#F319": "Disable",
                "SWGuardExtensions(SGX)#F308": "Enabled"
        }
}
EOF
) 


declare -A bios_snp_settings

bios_snp_settings["Lenovo"]="${lenovo_bios_snp_settings}"
bios_tdx_settings["Supermicro"]="${supermicro_tdx_settings}"



if [ "$redfish_vendor" == "Lenovo" ]; then
        echo "${bios_snp_settings[${redfish_vendor}]}" | jq .
        # Lenovo wants that users patch the Bios/Pending resource 
        # rather then Bios which is prohibited
        curl -X PATCH https://"${redfish_ipv4_ip}"/redfish/v1/Systems/1/Bios/Pending -u  "${REDFISH_USER}:${REDFISH_PASSWD}" -H "Content-Type: application/json" -d "${bios_snp_settings[${redfish_vendor}]}" -ks  | jq .
        curl -ks https://"${redfish_ipv4_ip}"/redfish/v1/Systems/1/Bios/Pending  -u  "${REDFISH_USER}:${REDFISH_PASSWD}" | jq .

        #curl -X POST https://"${redfish_ipv4_ip}"/redfish/v1/Systems/1/Actions/ComputerSystem.Reset -H "Content-Type: application/json" -d '{"ResetType": "GracefulRestart"}' -u  "${REDFISH_USER}:${REDFISH_PASSWD}" -ks | jq .
fi







