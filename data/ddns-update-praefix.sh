#!/usr/bin/env bash
PFAD="/data"
DATUM=$(date +%Y-%m-%d\ %H:%M:%S)
# set -e
if [[ "$NETWORK_CHECK" =~ (YES|yes|Yes) ]] ; then
    if ! curl -4sf --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/ipcheck.php" 2>&1 > /dev/null; then
        echo "$DATUM  ERROR !!!  - 404 You have no network or internet access or the website ipv64.net is not reachable"
        STATUS="OK"
        NAMESERVER_CHECK=$(dig +timeout=1 @${NAME_SERVER} 2>/dev/null)
        echo "$NAMESERVER_CHECK" | grep -s -q "timed out" && { NAMESERVER_CHECK="Timeout" ; STATUS="FAIL" ; }
        if [ "${STATUS}" = "FAIL" ] ; then
            echo "$DATUM  ERROR !!!  - 404 NAMESERVER ${NAME_SERVER} is not reachable. You have no network or internet access"
            echo "=============================================================================================="
        fi
        if ! curl -4sf "https://google.de" 2>&1 > /dev/null; then
            echo "$DATUM  ERROR !!!  - 404 You have no network or internet access or the website google.de is not reachable"
            echo "=============================================================================================="
            exit 1
        else
            IP_INFO=$(curl -4sf "https://ipinfo.io/ip" 2>/dev/null)
            UPDIP=$(cat $PFAD/updip.txt)
            echo "$DATUM    INFO !!!  - The website google.de is reachable. Your current IP according to IPINFO.IO=$IP_INFO"
            if [ "$IP_INFO" = "$UPDIP" ]; then
                echo > /dev/null
            else
                if [ -z "${SHOUTRRR_URL:-}" ] ; then
                    echo > /dev/null
                else
                    echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE is being sent"
                    DOMAIN_NOTIFY=$(for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "DOMAIN with PREFIX: ${DOMAIN_PRAEFIX}.${DOMAIN} "; done)
                    if ! /usr/local/bin/shoutrrr send --url "${SHOUTRRR_URL}" --message "`echo -e "$DATUM    INFO !!! \n\nIPV64.NET IS NOT REACHABLE \nYOUR Current IP according to IPINFO.IO=$IP_INFO \n${DOMAIN_NOTIFY}"`" 2>/dev/null; then
                        echo "$DATUM  ERROR !!!  - SHOUTRRR MESSAGE could not be sent"
                    else
                        echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE was sent"
                    fi
                fi
            fi
            echo "$IP_INFO" > $PFAD/updip.txt
            echo "=============================================================================================="
            exit 1
        fi
    fi
else
    echo > /dev/null
fi

PRIMARY_IP_SOURCES=(
    "https://ipinfo.io/ip"
    "https://ifconfig.me"
    "https://ifconfig.co/ip"
    "https://icanhazip.com"
    "https://api.ipify.org"
    "https://ipecho.net/plain"
    "https://ident.me"
    "https://checkip.amazonaws.com"
    "https://myexternalip.com/raw"
    "https://wtfismyip.com/text"
    "https://ip.tyk.nu"
    "https://ipv4.icanhazip.com"
    "https://ipv64.net/ipcheck.php?ipv4"
)
for url_ip in "${PRIMARY_IP_SOURCES[@]}"; do
    response=$(curl -4sSL --connect-timeout 2 --max-time 3 --user-agent "${CURL_USER_AGENT}" "$url_ip" 2>/dev/null)
    if [[ "$response" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        export IP_SOURCE="$url_ip"
        break
    fi
done
IP=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "$IP_SOURCE" 2>/dev/null)
UPDIP=$(cat $PFAD/updip.txt)
sleep 1

function SHOUTRRR_NOTIFY() {
echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE is being sent"
NOTIFY="
DOCKER DDNS UPDATER IPV64.NET - IP UPDATE !!!
\n
`for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "$DATUM  UPDATE !!! \nUpdate IP=$IP - Old-IP=$UPDIP  \nDOMAIN with PREFIX: ${DOMAIN_PRAEFIX}.${DOMAIN} \n"; done`"

if ! /usr/local/bin/shoutrrr send --url "${SHOUTRRR_URL}" --message "`echo -e "${NOTIFY}"`" 2>/dev/null; then
    echo "$DATUM  ERROR !!!  - SHOUTRRR MESSAGE could not be sent"
else
    echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE was sent"
fi
}

if [ "$IP" == "$UPDIP" ]; then
    echo "$DATUM  NO UPDATE - Current IP=$UPDIP"
else
    echo "$DATUM  UPDATE !!! ..."
    echo "$DATUM  UPDATE !!!  - Update IP=$IP - Old-IP=$UPDIP"
    sleep 1
    UPDATE_IP=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&praefix=${DOMAIN_PRAEFIX}&ip=${IP}&output=min" 2>/dev/null)
    if [[ "$UPDATE_IP" =~ (nochg|good|ok) ]] ; then
        echo "$DATUM  UPDATE !!!  - UPDATE IP=$IP HAS BEEN SENT TO IPV64.NET"
        if [ -z "${SHOUTRRR_URL:-}" ] ; then
            echo > /dev/null
        else
            SHOUTRRR_NOTIFY
        fi
        echo "$IP" > $PFAD/updip.txt
    else
        echo "$DATUM  ERROR !!!  - UPDATE IP=$IP WAS NOT SENT TO IPV64.NET"
        CHECK_INTERVALL=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&praefix=${DOMAIN_PRAEFIX}&ip=${IP}" | grep -o "Updateintervall")
        if [ "$CHECK_INTERVALL" == "Updateintervall" ]; then
            echo "$DATUM  ERROR !!!  - Your DynDNS update limit has likely been reached"
            echo "$DATUM    INFO !!!  - An update can only be sent again when your DynDNS update limit is in the green range"
        fi
        if [ -z "${SHOUTRRR_URL:-}" ] ; then
             echo > /dev/null
        else
            echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE is being sent"
            DOMAIN_NOTIFY=$(for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "DOMAIN with PREFIX: ${DOMAIN_PRAEFIX}.${DOMAIN} "; done)
            if ! /usr/local/bin/shoutrrr send --url "${SHOUTRRR_URL}" --message "`echo -e "$DATUM    INFO !!! \n\nUPDATE IP=$IP WAS NOT SENT TO IPV64.NET \n${DOMAIN_NOTIFY}"`" 2>/dev/null; then
                echo "$DATUM  ERROR !!!  - SHOUTRRR MESSAGE could not be sent"
            else
                echo "$DATUM  SHOUTRRR    - SHOUTRRR MESSAGE was sent"
            fi
        fi
    fi
fi

echo "=============================================================================================="
