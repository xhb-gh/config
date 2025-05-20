#!/bin/bash

# 检查是否提供了域名参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1
echo

echo "A Record:"
dig +noall +answer "${DOMAIN}" A
echo

echo "MX Record:"
dig +noall +answer "${DOMAIN}" MX
echo

echo "CNAME Record:"
dig +noall +answer "${DOMAIN}" CNAME
echo

echo "SPF Record:"
dig +noall +answer "${DOMAIN}" TXT | grep -i 'spf'
echo

echo "DMARC Record:"
dig +short TXT "_dmarc.${DOMAIN}"
echo

echo "DKIM Record:"
dig +short TXT "mail._domainkey.${DOMAIN}"
dig +short TXT "default._domainkey.${DOMAIN}"
echo

echo "rDNS (PTR) Record:"
for ip in $(dig +short "${DOMAIN}"); do
    dig +noall +answer -x "$ip"
done
echo

# bash dns_query.sh taojiang.online
# bash dns_query.sh gztech.online

# dig @8.8.8.8 +short gztech.online A
# dig @8.8.8.8 +short gztech.online MX
# dig @8.8.8.8 +short gztech.online TXT
# dig @8.8.8.8 +short -x 107.172.219.150
