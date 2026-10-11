function FindProxyForURL(url, host) {
    if (shExpMatch(host, '*.${domain}')) {
        return 'DIRECT';
    }

    if (isInNet(host, '10.42.10.0', '255.255.255.0')) {
        return 'DIRECT';
    }

    return 'PROXY squid.${domain}:3128; DIRECT';
}