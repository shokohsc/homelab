#!/usr/bin/env bash

log () {
    # if ("ERROR" === ${2}) {
    #     <&2 echo "$(date "+%Y-%m-%d %H:%M:%S") [ERROR]: $1"
    # }
    echo "[${2:-INFO}] $(date "+%Y-%m-%d %H:%M:%S") $1"
}

cleanup() {
    # When you run `docker stop` or any equivalent, a SIGTERM signal is sent to PID 1.
    # A process running as PID 1 inside a container is treated specially by Linux:
    # it ignores any signal with the default action. As a result, the process will
    # not terminate on SIGINT or SIGTERM unless it is coded to do so. Because of this,
    # I've defined behavior for when SIGINT and SIGTERM is received.
    if [[ -n "$openvpn_child" ]]; then
        log "Stopping OpenVPN..."
        kill -TERM "$openvpn_child" || true
    fi

    if [[ "$KILL_SWITCH" == "on" ]]; then
        log "Printing iptables rules."
        iptables -L

        log "Printing routes."
        ip route

        # local_subnet=$(ip r | grep -v 'default via' | grep eth0 | tail -n 1 | cut -d " " -f 1)

        log "Deleting VPN kill switch and local routes."

        log "Preventing established and related connections..."
        iptables -D INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "${header} Allow established and related connections"

        log "Preventing loopback connections..."
        iptables -D INPUT -i lo -j ACCEPT -m comment --comment "${header} Allow loopback input"
        iptables -D OUTPUT -o lo -j ACCEPT -m comment --comment "${header} Allow loopback output"

        # log "Preventing Docker network connections..."
        # iptables -D INPUT -s "$local_subnet" -j ACCEPT -m comment --comment "${header} Allow Docker network input"
        # iptables -D OUTPUT -d "$local_subnet" -j ACCEPT -m comment --comment "${header} Allow Docker network output"

        log "Preventing specified subnets..."
        # for every specified subnet...
        for subnet in ${SUBNETS//,/ }; do
            # # delete a route to it and...
            # ip route del "$subnet" via "$default_gateway" dev eth0 || true
            # prevent connections
            iptables -D INPUT -s "$subnet" -j ACCEPT -m comment --comment "${header} Allow subnet $subnet input"
            iptables -D OUTPUT -d "$subnet" -j ACCEPT -m comment --comment "${header} Allow subnet $subnet output"
        done

        log "Preventing specified ports..."
        # for every specified port...
        for line in ${PORTS//,/ }; do
            IFS=';' read -r -a part <<< "$line"
            port=${part[0]}
            protocol=${part[1]}
            iptables -D INPUT -p $protocol -m $protocol --dport $port -j ACCEPT -m comment --comment "${header} Allow $protocol port $port"
        done

        log "Preventing remote servers in configuration file..."
        global_port=$(grep "port " "$config_file_modified" | cut -d " " -f 2)
        global_protocol=$(grep "proto " "$config_file_modified" | cut -d " " -f 2 | cut -c1-3)
        remotes=$(grep "remote " "$config_file_modified")

        log "  Using:"
        comment_regex='^[[:space:]]*[#;]'
        echo "$remotes" | while IFS= read -r line; do
            # Ignore comments.
            if ! [[ "$line" =~ $comment_regex ]]; then
                # Remove the line prefix 'remote '.
                line=${line#remote }

                # Remove any trailing comments.
                line=${line%%#*}

                # Split the line into an array.
                # The first element is an address (IP or domain), the second is a port,
                # and the fourth is a protocol.
                IFS=' ' read -r -a remote <<< "$line"
                address=${remote[0]}
                # Use port from 'remote' line, then 'port' line, then '1194'.
                port=${remote[1]:-${global_port:-1194}}
                # Use protocol from 'remote' line, then 'proto' line, then 'udp'.
                protocol=${remote[2]:-${global_protocol:-udp}}

                # Map from OpenVPN tcp-client config option to tcp for iptables
                if [[ $protocol == "tcp-client" ]]; then
                    protocol='tcp'
                fi

                ip_regex='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'
                if [[ "$address" =~ $ip_regex ]]; then
                    log "    IP: $address PORT: $port PROTOCOL: $protocol"
                    iptables -D OUTPUT -o eth0 -d "$address" -p "$protocol" --dport "$port" -j ACCEPT -m comment --comment "${header} Allow $protocol to $address:$port"
                else
                    for ip in $(dig -4 +short "$address"); do
                        log "    $address (IP: $ip PORT: $port PROTOCOL: $protocol)"
                        iptables -D OUTPUT -o eth0 -d "$ip" -p "$protocol" --dport "$port" -j ACCEPT -m comment --comment "${header} Allow $protocol to $ip:$port"
                        echo "$ip $address" >> /etc/hosts
                    done
                fi
            fi
        done

        log "Preventing connections over VPN interface..."
        iptables -D INPUT -i tun0 -j ACCEPT -m comment --comment "${header} Allow VPN input"
        iptables -D OUTPUT -o tun0 -j ACCEPT -m comment --comment "${header} Allow VPN output"

        # log "Preventing traffic to port 8080 for kubelet readiness probe..."
        # iptables -D INPUT -p tcp -m tcp --dport 8080 -j ACCEPT -m comment --comment "${header} Allow traffic to port 8080 for kubelet readiness probe"

        log "Allowing anything else..."
        iptables -P INPUT ACCEPT -m comment --comment "${header} Accept all input"
        iptables -P OUTPUT DROP -m comment --comment "${header} Drop all output"
        iptables -P FORWARD DROP -m comment --comment "${header} Drop all forwarding"

        log "iptables rules deleted and routes configured."

        log "Printing iptables rules."
        iptables -L

    else
        log "VPN kill switch is disabled. Traffic will be allowed outside of the tunnel if the connection is lost." "WARNING"
        # log "Deleting routes to specified subnets..."
        # for subnet in ${SUBNETS//,/ }; do
        #     ip route del "$subnet" via "$default_gateway" dev eth0 || true
        # done
        # log "Routes deleted."
    fi

    log "Printing routes."
    ip route

    sleep 1
    log "Removing ${config_file_original}."
    rm "$config_file_original"

    log "Removing ${config_file_modified}."
    rm "$config_file_modified"

    log "Exiting."
    exit 0
}

# OpenVPN log levels are 1-11.
# shellcheck disable=SC2153
if [[ "$VPN_LOG_LEVEL" -lt 1 || "$VPN_LOG_LEVEL" -gt 11 ]]; then
    log "Invalid log level $VPN_LOG_LEVEL. Setting to default." "WARNING"
    vpn_log_level=3
else
    vpn_log_level=$VPN_LOG_LEVEL
fi

log "
---- Running with the following variables ----
Kill switch: ${KILL_SWITCH:-off}
HTTP proxy: ${HTTP_PROXY:-off}
SOCKS proxy: ${SOCKS_PROXY:-off}
Keep DNS settings unchanged: ${KEEP_DNS_UNCHANGED:-off}
Proxy username secret: ${PROXY_PASSWORD_SECRET:-none}
Proxy password secret: ${PROXY_USERNAME_SECRET:-none}
Allowing subnets: ${SUBNETS:-none}
Using OpenVPN log level: $vpn_log_level
Listening on: ${LISTEN_ON:-none}"

if [[ -n "$VPN_CONFIG_FILE" ]]; then
    config_file_original="/data/vpn/$VPN_CONFIG_FILE"
elif [[ -n "$VPN_CONFIG_PATTERN" ]]; then
    # Capture the filename of the random .conf file according to the pattern to use as OpenVPN config.
    config_file_original=$(find /data/vpn -name "$VPN_CONFIG_PATTERN" 2> /dev/null | sort | shuf -n 1)
else
    # Capture the filename of the random .conf file to use as the OpenVPN config.
    config_file_original=$(find /data/vpn -name "*.conf" 2> /dev/null | sort | shuf -n 1)
fi

if [[ -z "$config_file_original" ]]; then
    log "No configuration file found. Please check your mount and file permissions. Exiting." "ERROR"
    exit 1
fi

log "Using configuration file: $config_file_original"

# Create a new configuration file to modify so the original is left untouched.
config_file_modified="${config_file_original}.modified"

log "Creating $config_file_modified and making required changes to that file."
grep -Ev "(^up\s|^down\s)" "$config_file_original" > "$config_file_modified"

# These configuration file changes are required by Alpine.
# Also replace carriage return char for conversion of CRLF to LF line endings
sed -i \
    -e 's/^proto udp$/proto udp4/' \
    -e 's/^proto tcp$/proto tcp4/' \
    -e 's/\r$//' \
    "$config_file_modified"

if [[ "$KEEP_DNS_UNCHANGED" != "on" ]]; then
    echo "up /etc/openvpn/up.sh" >> "$config_file_modified"
    echo "down /etc/openvpn/down.sh" >> "$config_file_modified"
fi

log "Changes made."

trap cleanup SIGINT SIGTERM EXIT ERR

date="$(date "+%Y-%m-%d %H:%M:%S")"
header="[$(hostname) ${date}]"
# default_gateway=$(ip r | grep 'default via' | cut -d " " -f 3)
if [[ "$KILL_SWITCH" == "on" ]]; then
    log "Printing iptables rules."
    iptables -L

    log "Printing routes."
    ip route

    # local_subnet=$(ip r | grep -v 'default via' | grep eth0 | tail -n 1 | cut -d " " -f 1)

    log "Creating VPN kill switch and local routes."

    log "Allowing established and related connections..."
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT -m comment --comment "${header} Allow established and related connections"

    log "Allowing loopback connections..."
    iptables -A INPUT -i lo -j ACCEPT -m comment --comment "${header} Allow loopback input"
    iptables -A OUTPUT -o lo -j ACCEPT -m comment --comment "${header} Allow loopback output"

    # log "Allowing Docker network connections..."
    # iptables -A INPUT -s "$local_subnet" -j ACCEPT -m comment --comment "${header} Allow Docker network input"
    # iptables -A OUTPUT -d "$local_subnet" -j ACCEPT -m comment --comment "${header} Allow Docker network output"

    log "Allowing specified subnets..."
    # for every specified subnet...
    for subnet in ${SUBNETS//,/ }; do
        # # create a route to it and...
        # ip route add "$subnet" via "$default_gateway" dev eth0 || true
        # allow connections
        iptables -A INPUT -s "$subnet" -j ACCEPT -m comment --comment "${header} Allow subnet $subnet input"
        iptables -A OUTPUT -d "$subnet" -j ACCEPT -m comment --comment "${header} Allow subnet $subnet output"
    done

    log "Allowing specified ports..."
    # for every specified port...
    for line in ${PORTS//,/ }; do
        IFS=';' read -r -a part <<< "$line"
        port=${part[0]}
        protocol=${part[1]}
        iptables -A INPUT -p $protocol -m $protocol --dport $port -j ACCEPT -m comment --comment "${header} Allow $protocol port $port"
    done

    log "Allowing remote servers in configuration file..."
    global_port=$(grep "port " "$config_file_modified" | cut -d " " -f 2)
    global_protocol=$(grep "proto " "$config_file_modified" | cut -d " " -f 2 | cut -c1-3)
    remotes=$(grep "remote " "$config_file_modified")

    log "  Using:"
    comment_regex='^[[:space:]]*[#;]'
    echo "$remotes" | while IFS= read -r line; do
        # Ignore comments.
        if ! [[ "$line" =~ $comment_regex ]]; then
            # Remove the line prefix 'remote '.
            line=${line#remote }

            # Remove any trailing comments.
            line=${line%%#*}

            # Split the line into an array.
            # The first element is an address (IP or domain), the second is a port,
            # and the fourth is a protocol.
            IFS=' ' read -r -a remote <<< "$line"
            address=${remote[0]}
            # Use port from 'remote' line, then 'port' line, then '1194'.
            port=${remote[1]:-${global_port:-1194}}
            # Use protocol from 'remote' line, then 'proto' line, then 'udp'.
            protocol=${remote[2]:-${global_protocol:-udp}}

            # Map from OpenVPN tcp-client config option to tcp for iptables
            if [[ $protocol == "tcp-client" ]]; then
                protocol='tcp'
            fi

            ip_regex='^(([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))\.){3}([1-9]?[0-9]|1[0-9][0-9]|2([0-4][0-9]|5[0-5]))$'
            if [[ "$address" =~ $ip_regex ]]; then
                log "    IP: $address PORT: $port PROTOCOL: $protocol"
                iptables -A OUTPUT -o eth0 -d "$address" -p "$protocol" --dport "$port" -j ACCEPT -m comment --comment "${header} Allow $protocol to $address:$port"
            else
                for ip in $(dig -4 +short "$address"); do
                    log "    $address (IP: $ip PORT: $port PROTOCOL: $protocol)"
                    iptables -A OUTPUT -o eth0 -d "$ip" -p "$protocol" --dport "$port" -j ACCEPT -m comment --comment "${header} Allow $protocol to $ip:$port"
                    echo "$ip $address" >> /etc/hosts
                done
            fi
        fi
    done

    log "Allowing connections over VPN interface..."
    iptables -A INPUT -i tun0 -j ACCEPT -m comment --comment "${header} Allow VPN input"
    iptables -A OUTPUT -o tun0 -j ACCEPT -m comment --comment "${header} Allow VPN output"

    # log "Allowing traffic to port 8080 for kubelet readiness probe..."
    # iptables -A INPUT -p tcp -m tcp --dport 8080 -j ACCEPT -m comment --comment "${header} Allow traffic to port 8080 for kubelet readiness probe"

    log "Preventing anything else..."
    iptables -P INPUT DROP -m comment --comment "${header} Drop all input"
    iptables -P OUTPUT DROP -m comment --comment "${header} Drop all output"
    iptables -P FORWARD DROP -m comment --comment "${header} Drop all forwarding"

    log "iptables rules created and routes configured."

    log "Printing iptables rules."
    iptables -L
else
    log "VPN kill switch is disabled. Traffic will be allowed outside of the tunnel if the connection is lost." "WARNING"
    # log "Creating routes to specified subnets..."
    # for subnet in ${SUBNETS//,/ }; do
    #     ip route add "$subnet" via "$default_gateway" dev eth0 || true
    # done
    # log "Routes created."
fi

log "Printing routes."
ip route
set +x

if [[ "$HTTP_PROXY" == "on" ]]; then
    if [[ -n "$PROXY_USERNAME" ]]; then
        if [[ -n "$PROXY_PASSWORD" ]]; then
            log "Configuring HTTP proxy authentication."
            echo -e "\nBasicAuth $PROXY_USERNAME $PROXY_PASSWORD" >> /data/tinyproxy.conf
        else
            log "Proxy username supplied without password. Starting HTTP proxy without credentials." "WARNING"
        fi
    elif [[ -f "/run/secrets/$PROXY_USERNAME_SECRET" ]]; then
        if [[ -f "/run/secrets/$PROXY_PASSWORD_SECRET" ]]; then
            log "Configuring proxy authentication."
            echo -e "\nBasicAuth $(cat /run/secrets/$PROXY_USERNAME_SECRET) $(cat /run/secrets/$PROXY_PASSWORD_SECRET)" >> /data/tinyproxy.conf
        else
            log "Credentials secrets not read. Starting HTTP proxy without credentials." "WARNING"
        fi
    fi
    /data/scripts/tinyproxy_wrapper.sh &
fi

if [[ "$SOCKS_PROXY" == "on" ]]; then
    if [[ -n "$LISTEN_ON" ]]; then
            sed -i "s/internal: eth0/internal: $LISTEN_ON/" /data/sockd.conf
    fi
    if [[ -n "$PROXY_USERNAME" ]]; then
        if [[ -n "$PROXY_PASSWORD" ]]; then
            log "Configuring SOCKS proxy authentication."
            adduser -S -D -g "$PROXY_USERNAME" -H -h /dev/null "$PROXY_USERNAME"
            echo "$PROXY_USERNAME:$PROXY_PASSWORD" | chpasswd 2> /dev/null
            sed -i 's/socksmethod: none/socksmethod: username/' /data/sockd.conf
        else
            log "Proxy username supplied without password. Starting SOCKS proxy without credentials." "WARNING"
        fi
    elif [[ -f "/run/secrets/$PROXY_USERNAME_SECRET" ]]; then
        if [[ -f "/run/secrets/$PROXY_PASSWORD_SECRET" ]]; then
            log "Configuring proxy authentication."
            adduser -S -D -g "$(cat /run/secrets/$PROXY_USERNAME_SECRET)" -H -h /dev/null "$(cat /run/secrets/$PROXY_USERNAME_SECRET)"
            echo "$(cat /run/secrets/$PROXY_USERNAME_SECRET):$(cat /run/secrets/$PROXY_PASSWORD_SECRET)" | chpasswd 2> /dev/null
            sed -i 's/socksmethod: none/socksmethod: username/' /data/sockd.conf
        else
            log "Credentials secrets not present. Starting SOCKS proxy without credentials." "WARNING"
        fi
    fi
    /data/scripts/dante_wrapper.sh &
fi

openvpn_args=(
    "--config" "$config_file_modified"
    "--auth-nocache"
    "--cd" "/data/vpn"
    "--pull-filter" "ignore" "ifconfig-ipv6"
    "--pull-filter" "ignore" "route-ipv6"
    "--script-security" "2"
    "--up-restart"
    "--verb" "$vpn_log_level"
)

if [[ -n "$VPN_AUTH_SECRET" ]]; then
    if [[ -f "/run/secrets/$VPN_AUTH_SECRET" ]]; then
        log "Configuring OpenVPN authentication."
        openvpn_args+=("--auth-user-pass" "/run/secrets/$VPN_AUTH_SECRET")
    else
        log "OpenVPN credentials secrets not present." "WARNING"
    fi
fi

log "Running OpenVPN client."

openvpn "${openvpn_args[@]}" &
openvpn_child=$!

wait $openvpn_child