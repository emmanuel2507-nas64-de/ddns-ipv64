#!/usr/bin/env bash
# set -e
DATUM=$(date +%Y-%m-%d\ %H:%M:%S)

if [[ "$NETWORK_CHECK" =~ (YES|yes|Yes) ]] ; then
    if ! curl -6sf --user-agent "${CURL_USER_AGENT}" "https://ipv64.net/ipcheck.php" 2>&1 > /dev/null; then
        echo "$DATUM  ERROR !!!  - 404 You have no network or internet access or the website ipv64.net is not reachable"
        echo "=============================================================================================="
        exit 1
    fi
    STATUS="OK"
    NAMESERVER_CHECK=$(dig +timeout=1 @${NAME_SERVER} 2>/dev/null)
    echo "$NAMESERVER_CHECK" | grep -s -q "timed out" && { NAMESERVER_CHECK="Timeout" ; STATUS="FAIL" ; }
    if [ "${STATUS}" = "FAIL" ] ; then
        echo "$DATUM  ERROR !!!  - 404 NAMESERVER ${NAME_SERVER} is not reachable. You have no network or internet access"
        echo "=============================================================================================="
        exit 1
    fi
else
    echo > /dev/null
fi

if [[ "${DOMAIN_PRAEFIX_YES}" =~ (YES|yes|Yes) ]] ; then
    for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do
        echo "`date +%Y-%m-%d\ %H:%M:%S`  IP CHECK    - Your DOMAIN with PREFIX ${DOMAIN_PRAEFIX}.${DOMAIN} HAS THE IP=`dig +short ${DOMAIN_PRAEFIX}.${DOMAIN} A @${NAME_SERVER}`" >> /data/log/cron.log 2>&1
    done
else
    for DOMAIN in $(echo "${DOMAIN_IPV64}" | sed -e "s/,/ /g"); do
        echo "`date +%Y-%m-%d\ %H:%M:%S`  IP CHECK    - Your DOMAIN ${DOMAIN} HAS THE IP=`dig +short ${DOMAIN} A @${NAME_SERVER}`" >> /data/log/cron.log 2>&1
    done
fi
echo "=============================================================================================="
