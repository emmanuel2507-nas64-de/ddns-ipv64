#!/usr/bin/env bash
# set -x
# set -e
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
sleep 1
DATUM=$(date +%Y-%m-%d\ %H:%M:%S)
# cleanup
cleanup() {
    echo "=============================================================================================="
    echo "================================  STOP DDNS UPDATER IPV4.NET ================================"
    echo "=============================================================================================="
    echo "=========================  ######     #######    #######    #######  ========================="
    echo "=========================  #     #       #       #     #    #     #  ========================="
    echo "=========================  #             #       #     #    #     #  ========================="
    echo "=========================   #####        #       #     #    ######   ========================="
    echo "=========================        #       #       #     #    #        ========================="
    echo "=========================  #     #       #       #     #    #        ========================="
    echo "=========================   #####        #       #######    #        ========================="
    echo "=============================================================================================="
}

# Trap SIGTERM
trap 'cleanup' SIGTERM

sleep 5
echo "=============================================================================================="
echo "================================ START DDNS UPDATER IPV4.NET ================================"
echo "=============================================================================================="
echo "================  ######    ########     ##     ##     #######     ##    ##   ================"
echo "================    ##      ##     ##    ##     ##    ##     ##    ##    ##   ================"
echo "================    ##      ##     ##    ##     ##    ##           ##    ##   ================"
echo "================    ##      ########     ##     ##    ########     ##    ##   ================"
echo "================    ##      ##            ##   ##     ##     ##    #########  ================"
echo "================    ##      ##             ## ##      ##     ##          ##   ================"
echo "================  ######    ##              ###        #######           ##   ================"
echo "=============================================================================================="

# echo -n "" > /data/log/cron.log
sleep 5
################################
# Set user and group ID
if [ "$PUID" != "0" ] || [ "$PGID" != "0" ]; then
    chown -R "$PUID":"$PGID" /data
    if [ ! -d "/data/log" ]; then
        install -d -o $PUID -g $PGID -m 755 /data/log
    fi
    if [ ! -f "/data/log/cron.log" ]; then
        install -o $PUID -g $PGID -m 644 /dev/null /data/log/cron.log
    fi
    if [ ! -f "/data/updip.txt" ]; then
        install -o $PUID -g $PGID -m 644 /dev/null /data/updip.txt
    fi
    echo "$DATUM  RECHTE      - Ornder /data UID: $PUID and GID: $PGID"
fi
if [ ! -d "/data/log" ]; then
    install -d -o $PUID -g $PGID -m 755 /data/log
fi
if [ ! -f "/data/log/cron.log" ]; then
    install -o $PUID -g $PGID -m 644 /dev/null /data/log/cron.log
fi
################################
MAX_LINES=1 /usr/local/bin/log-rotate.sh
################################
if [[ "${DOMAIN_PRAEFIX_YES}" =~ (YES|yes|Yes) ]] ; then
    if [ -z "${DOMAIN_PRAEFIX:-}" ] ; then
        echo "$DATUM  PRAEFIX     - You have not set a DOMAIN PREFIX, check https://ipv64.net/dyndns for Domain"
        sleep infinity
    else
        echo "$DATUM  PRAEFIX     - You have set a DOMAIN PREFIX"
    fi
    if [ -z "${DOMAIN_IPV64:-}" ] ; then
        echo "$DATUM  DOMAIN      - You have not set a DOMAIN, check https://ipv64.net/dyndns for Domain"
        sleep infinity
    else
        echo "$DATUM  DOMAIN      - You have set a DOMAIN"
        for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "$DATUM  DOMAIN      - Your DOMAIN with PREFIX ${DOMAIN_PRAEFIX}.${DOMAIN}"; done
    fi
else
    if [ -z "${DOMAIN_IPV64:-}" ] ; then
        echo "$DATUM  DOMAIN      - You have not set a DOMAIN, check https://ipv64.net/dyndns for Domain"
        sleep infinity
    else
        echo "$DATUM  DOMAIN      - You have set a DOMAIN"
        for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "$DATUM  DOMAIN      - Your DOMAIN ${DOMAIN}"; done
    fi
fi

if [ -z "${DOMAIN_KEY:-}" ] ; then
    echo "$DATUM  DOMAIN KEY  - You have not set a DOMAIN Key, check https://ipv64.net/dyndns for DynDNS Updatehash"
    sleep infinity
else
    echo "$DATUM  DOMAIN KEY  - You have set a DOMAIN Key"
fi

if [ -z "${CRON_TIME:-}" ] ; then
    echo "$DATUM  ERROR !!!  - You have not set the Environment CRON_TIME"
    sleep infinity
fi

if [ -z "${CRON_TIME_DIG:-}" ] ; then
    echo "$DATUM  ERROR !!!  - You have not set the Environment CRON_TIME_DIG"
    sleep infinity
fi

if [[ "$NETWORK_CHECK" =~ (YES|yes|Yes) ]] ; then
    while true; do
        if ! curl -4sf --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/ipcheck.php" 2>&1 > /dev/null; then
            echo "$DATUM  ERROR !!!  - 404 You have no network or internet access or the website ipv64.net is not reachable"
            sleep 900
            echo "=============================================================================================="
        else
            break
        fi
    done
    while true; do
        STATUS="OK"
        NAMESERVER_CHECK=$(dig +timeout=1 @${NAME_SERVER} 2>/dev/null)
        echo "$NAMESERVER_CHECK" | grep -s -q "timed out" && { NAMESERVER_CHECK="Timeout" ; STATUS="FAIL" ; }
        if [ "${STATUS}" = "FAIL" ] ; then
            echo "$DATUM  ERROR !!!  - 404 NAMESERVER ${NAME_SERVER} is not reachable. You have no network or internet access"
            sleep 900
            echo "=============================================================================================="
        else
            break
        fi
    done
else
    echo > /dev/null
fi

if [ -z "${SHOUTRRR_URL:-}" ] ; then
    echo "$DATUM  SHOUTRRR    - You have not set a SHOUTRRR URL"
else
    echo "$DATUM  SHOUTRRR    - You have set a SHOUTRRR URL"
    if [[ "${SHOUTRRR_SKIP_TEST}" =~ (NO|no|No) ]] ; then
        if ! /usr/local/bin/shoutrrr send --url "${SHOUTRRR_URL}" --message "`echo -e "$DATUM  TEST !!! \nDDNS Updater in Docker for Free DynDNS IPv64.net"`" 2>/dev/null; then
            echo "$DATUM  ERROR !!!  - The details are incorrectly set: SHOUTRRR URL"
            echo "$DATUM    INFO !!!  - Check https://containrrr.dev/shoutrrr/ for the correct URL format"
            echo "$DATUM    INFO !!!  - Stop the container and restart it with the correct details"
            sleep infinity
        else
            echo "$DATUM  CHECK       - The details are correctly set: SHOUTRRR URL"
        fi
    else
        echo "$DATUM  SHOUTRRR    - You have skipped the Shoutrrr test message."
    fi
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

function Domain_default() {
if [ -f /etc/.firstrun ]; then
    CHECK=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&ip=${IP}&output=min" 2>/dev/null)
    if [[ "$CHECK" =~ (nochg|good|ok) ]] ; then
        echo "$DATUM  CHECK       - The details are correctly set: DOMAIN and DOMAIN KEY"
        sleep 5
        if [[ "$IP_CHECK" =~ (YES|yes|Yes) ]] ; then
            for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "$DATUM  IP CHECK    - Your DOMAIN ${DOMAIN} HAS THE IP=`dig +short ${DOMAIN} A @${NAME_SERVER}`"; done
        else
            echo > /dev/null
        fi
        echo "${IP}" > /data/updip.txt
        sleep 2
        rm /etc/.firstrun
    else
        CHECK_INTERVALL=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&ip=${IP}" | grep -o "Updateintervall")
        if [ "$CHECK_INTERVALL" == "Updateintervall" ]; then
            echo "$DATUM  CHECK       - The details are correctly set: DOMAIN and DOMAIN KEY"
            echo "$DATUM  ERROR !!!  - Your DynDNS update limit has likely been reached"
            echo "$DATUM    INFO !!!  - An update can only be sent again when your DynDNS update limit is in the green"
        else
            echo "$DATUM  ERROR !!!  - The details are incorrectly set: DOMAIN or DOMAIN KEY"
            echo "$DATUM    INFO !!!  - Stop the container and restart it with the correct details"
            return
        fi
    fi
else
    echo "$DATUM  CHECK       - The details are correctly set: DOMAIN and DOMAIN KEY"
fi

echo "${CRON_TIME} /bin/bash /usr/local/bin/ddns-update.sh >> /data/log/cron.log 2>&1" > /etc/cron.d/container_cronjob
if [[ "$IP_CHECK" =~ (YES|yes|Yes) ]] ; then
    echo "${CRON_TIME_DIG} sleep 20 && /bin/bash /usr/local/bin/domain-ip-scheck.sh >> /data/log/cron.log 2>&1" >> /etc/cron.d/container_cronjob
else
    echo > /dev/null
fi
}

function Domain_add_praefix() {
if [ -f /etc/.firstrun ]; then
    CHECK=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&praefix=${DOMAIN_PRAEFIX}&ip=${IP}&output=min" 2>/dev/null)
    if [[ "$CHECK" =~ (nochg|good|ok) ]] ; then
        echo "$DATUM  CHECK       - The details are correctly set: DOMAIN with PREFIX and DOMAIN KEY"
        sleep 5
        if [[ "$IP_CHECK" =~ (YES|yes|Yes) ]] ; then
            for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do echo "$DATUM  IP CHECK    - Your DOMAIN with PREFIX ${DOMAIN_PRAEFIX}.${DOMAIN} HAS THE IP=`dig +short ${DOMAIN_PRAEFIX}.${DOMAIN} A @${NAME_SERVER}`"; done
        else
            echo > /dev/null
        fi
        echo "${IP}" > /data/updip.txt
        sleep 2
        rm /etc/.firstrun
    else
        CHECK_INTERVALL=$(curl -4sSL --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/update.php?key=${DOMAIN_KEY}&domain=${DOMAIN_IPV64}&praefix=${DOMAIN_PRAEFIX}&ip=${IP}" | grep -o "Updateintervall")
        if [ "$CHECK_INTERVALL" == "Updateintervall" ]; then
            echo "$DATUM  CHECK       - The details are correctly set: DOMAIN with PREFIX and DOMAIN KEY"
            echo "$DATUM  ERROR !!!  - Your DynDNS update limit has likely been reached"
            echo "$DATUM    INFO !!!  - An update can only be sent again when your DynDNS update limit is in the green"
        else
            echo "$DATUM  ERROR !!!  - The details are incorrectly set: DOMAIN with PREFIX or DOMAIN KEY"
            echo "$DATUM    INFO !!!  - Stop the container and restart it with the correct details"
            return
        fi
    fi
else
    echo "$DATUM  CHECK       - The details are correctly set: DOMAIN with PREFIX and DOMAIN KEY"
fi

echo "${CRON_TIME} /bin/bash /usr/local/bin/ddns-update-praefix.sh >> /data/log/cron.log 2>&1" > /etc/cron.d/container_cronjob
if [[ "$IP_CHECK" =~ (YES|yes|Yes) ]] ; then
    echo "${CRON_TIME_DIG} sleep 20 && /bin/bash /usr/local/bin/domain-ip-scheck.sh >> /data/log/cron.log 2>&1" >> /etc/cron.d/container_cronjob
else
    echo > /dev/null
fi
}

if [[ "$DOMAIN_PRAEFIX_YES" =~ (YES|yes|Yes) ]] ; then
    Domain_add_praefix
else
    Domain_default
fi

echo "*/30 * * * * /usr/local/bin/log-rotate.sh" >> /etc/cron.d/container_cronjob

/usr/bin/crontab /etc/cron.d/container_cronjob
/usr/sbin/crond
echo "================="
set tail -f /data/log/cron.log "$@"
exec "$@" &

wait $!
