
###################################
##      DNS records Adlist       ##
###################################

resource "routeros_ip_dns_adlist" "pgl-yoyo-org-adservers" {
  url = "https://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=1&mimetype=plaintext"
}
resource "routeros_ip_dns_adlist" "malware-filter" {
  url = "https://malware-filter.gitlab.io/malware-filter/phishing-filter-wildcard.txt"
}
resource "routeros_ip_dns_adlist" "phishing_army_blocklist" {
  url = "https://phishing.army/download/phishing_army_blocklist_extended.txt"
}
resource "routeros_ip_dns_adlist" "urlhaus-abuse-hostfile" {
  url = "https://urlhaus.abuse.ch/downloads/hostfile/"
}

resource "routeros_ip_dns_adlist" "TGTwilight-AWAvenue-Ads-Rule" {
  url = "https://github.com/TG-Twilight/AWAvenue-Ads-Rule/raw/refs/heads/main/Filters/AWAvenue-Ads-Rule-RouterOS-Adlist.txt"
}
resource "routeros_ip_dns_adlist" "Perflyst-PiHoleBlocklist" {
  url = "https://github.com/Perflyst/PiHoleBlocklist/raw/refs/heads/master/SmartTV.txt"
}
resource "routeros_ip_dns_adlist" "StevenBlack-hosts" {
  url = "https://github.com/StevenBlack/hosts/raw/refs/heads/master/hosts"
}
resource "routeros_ip_dns_adlist" "hoshsadiq-adblock-nocoin-list" {
  url = "https://github.com/hoshsadiq/adblock-nocoin-list/raw/refs/heads/master/hosts.txt"
}
resource "routeros_ip_dns_adlist" "durablenapkin-scamblocklist" {
  url = "https://github.com/durablenapkin/scamblocklist/raw/refs/heads/master/hosts.txt"
}
resource "routeros_ip_dns_adlist" "ShadowWhisperer-BlockLists" {
  url = "https://github.com/ShadowWhisperer/BlockLists/raw/refs/heads/master/Lists/Malware"
}
resource "routeros_ip_dns_adlist" "AssoEchap-stalkerware-indicators" {
  url = "https://github.com/AssoEchap/stalkerware-indicators/raw/refs/heads/master/generated/hosts"
}

resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-popupads" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/popupads.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-gambling" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/gambling.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-fake" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/fake.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-nosafesearch" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/nosafesearch.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-dyndns" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/dyndns.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-hoster" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/hoster.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-amazon" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.amazon.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-apple" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.apple.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-huawei" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.huawei.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-winoffice" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.winoffice.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-samsung" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.samsung.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-tiktok-extended" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.tiktok.extended.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-lgwebos" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.lgwebos.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-roku" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.roku.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-vivo" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.vivo.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-oppo-realme" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.oppo-realme.txt"
}
resource "routeros_ip_dns_adlist" "hagezi-dns-blocklists-native-xiaomi" {
  url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/wildcard/native.xiaomi.txt"
}
