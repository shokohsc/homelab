#!/usr/bin/env sh

log () {
  echo "$(date "+%Y-%m-%d %H:%M:%S") [${2:-INFO}]: $1"
}

country_picker () {
    # Define countries and their timezone offsets from UTC (24-hour format)
    COUNTRIES="russia japan korea thailand usa"
    OFFSETS="3 9 9 7 -5"

    # Get the current UTC hour
    UTC_HOUR=$(date -u +%H)

    # Initialize a list of valid countries
    VALID_COUNTRIES=""

    # Iterate through the country list and determine if it's day or night in each
    i=1
    for COUNTRY in $COUNTRIES; do
        # Get corresponding UTC offset
        set -- $OFFSETS
        OFFSET=$(eval echo \$$i)

        # Calculate local hour
        LOCAL_HOUR=$(( (UTC_HOUR + OFFSET) % 24 ))
        if [ "$LOCAL_HOUR" -lt 0 ]; then
            LOCAL_HOUR=$(( LOCAL_HOUR + 24 ))
        fi

        # Determine if it's day or night
        if [ "$LOCAL_HOUR" -ge 8 ] && [ "$LOCAL_HOUR" -lt 20 ]; then
            TIME_PERIOD="Day"
        else
            TIME_PERIOD="Night"
        fi

        # Check if the time period matches the current UTC hour
        CURRENT_UTC_PERIOD="Night"
        if [ "$UTC_HOUR" -ge 8 ] && [ "$UTC_HOUR" -lt 20 ]; then
            CURRENT_UTC_PERIOD="Day"
        fi

        # Pick countries that are not in the matching day or night period
        if [ "$TIME_PERIOD" != "$CURRENT_UTC_PERIOD" ]; then
            VALID_COUNTRIES="$VALID_COUNTRIES $COUNTRY"
        fi

        i=$((i + 1))
    done

    # Pick a random country from the valid ones
    if [ -n "$VALID_COUNTRIES" ]; then
        set -- $VALID_COUNTRIES
        RAND=$(( ($RANDOM % $#) + 1 ))
        COUNTRY=$(eval echo \$$RAND)

        echo "$COUNTRY"
    fi
}

# Function to gather labeled metrics
push_metrics() {
    # Prometheus metrics format output with labels
    metrics=$(cat <<EOF
# HELP pod_gateway_profile_request Dummy metric to represent a profile request
# TYPE pod_gateway_profile_request gauge
pod_gateway_profile_request{country="$1", ipv4="$2", protocol="$3", provider="$4", identifier="$(hostname)"} 1
EOF
    )

    # Save metrics to a temporary file
    echo "$metrics" > /tmp/metrics.txt

    # Push the metrics to the Pushgateway using wget (vector)
    wget --method=PUT --body-file=/tmp/metrics.txt http://localhost:9091/metrics
}

ovpn_profile="/data/vpn/profile.conf"
if [ -f $ovpn_profile ]; then
  log "Removing existing openvpn configuration" "DEBUG"
  rm $ovpn_profile
fi
touch $ovpn_profile
log "Downloading new openvpn configuration" "DEBUG"
# country=$(country_picker)
country=""
if [ -z $country ]; then
    wget --header "identifier: $(hostname)" --header "Cache-Control': 'public,max-age=3600'" -O- http://api.sidekick.svc.cluster.local:3000/vpn/profile/ovpn  | tr -d '\r' >$ovpn_profile
else
    wget --header "identifier: $(hostname)" --header "Cache-Control': 'public,max-age=3600'" -O- "http://api.sidekick.svc.cluster.local:3000/vpn/profile/ovpn?country=$country"  | tr -d '\r' >$ovpn_profile
fi

# command -v curl >/dev/null || apk add --no-cache curl
# curl -s -H "identifier: $(hostname)" -H "Cache-Control': 'public,max-age=3600'" -D headers.txt -o $ovpn_profile http://api.sidekick.svc.cluster.local:3000/vpn/profile/ovpn
if [ $? != 0 ]; then
  log "Cannot get ovpn profile" 'ERROR'
  exit 1
fi

# country=$(grep 'X-Vpn-Country: ' headers.txt | cut -d' ' -f2-)
# ipv4=$(grep 'X-Vpn-Ipv4: ' headers.txt | cut -d' ' -f2-)
# protocol=$(grep 'X-Vpn-Protocol: ' headers.txt | cut -d' ' -f2-)
# provider=$(grep 'X-Vpn-Provider: ' headers.txt | cut -d' ' -f2-)
# # Call the push_metrics function with the extracted values
# push_metrics "$country" "$ipv4" "$protocol" "$provider"

log "Editing downloaded openvpn configuration" "DEBUG"
echo "auth-retry none" >> $ovpn_profile
echo "server-poll-timeout 5"  >> $ovpn_profile
echo "connect-timeout 5" >> $ovpn_profile
# echo "explicit-exit-notify 2" >> $ovpn_profile
echo "replay-window 64 15" >> $ovpn_profile
echo "mute-replay-warnings" >> $ovpn_profile
echo "dhcp-option DNS 94.140.14.14" >> $ovpn_profile
echo "dhcp-option DNS 94.140.15.15" >> $ovpn_profile

log "Starting openvpn" "DEBUG"
/data/scripts/entry.sh &
entry=$!

_kill_procs() {
  log "Signal received -> killing processes"

  kill -TERM $entry
  wait $entry
  rc=$?

  rc=$(( $rc || $? ))
  log "Terminated with RC: $rc"
  exit $rc
}

trap _kill_procs SIGTERM

wait $entry
rc=$?

log "TERMINATING"

rc=$(( $rc || $? ))
log "Terminated with RC: $rc"
exit $rc
