#!/bin/bash

# 检查是否提供了域名参数
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1

apt update
apt install certbot
certbot certonly --standalone -d $FQDN --email 3096459788@qq.com --agree-tos

ARCHIVE_DIR="/etc/letsencrypt/archive/${DOMAIN}"
DEST_DIR="/etc/letsencrypt/live/${DOMAIN}"

ls DEST_DIR # 当前活动证书的 符号链接，供服务器和应用程序使用。
rm -f "${DEST_DIR}/*" # 移除所有 符号链接
ls ARCHIVE_DIR  # 所有版本的实际证书文件和私钥文件，历史档案

LATEST_VERSION=$(find ${ARCHIVE_DIR} -name 'cert*.pem' -printf '%f\n' | sed -r 's/cert([0-9]+).pem/\1/' | sort -n | tail -n 1)
echo "LATEST_VERSION: ${LATEST_VERSION}"

echo "将${ARCHIVE_DIR}中最新的cert证书复制到${DEST_DIR}"
cp ${ARCHIVE_DIR}/cert${LATEST_VERSION}.pem ${DEST_DIR}/cert.pem
cp ${ARCHIVE_DIR}/privkey${LATEST_VERSION}.pem ${DEST_DIR}/privkey.pem
cp ${ARCHIVE_DIR}/chain${LATEST_VERSION}.pem ${DEST_DIR}/chain.pem
cp ${ARCHIVE_DIR}/fullchain${LATEST_VERSION}.pem ${DEST_DIR}/fullchain.pem

# bash myCertbot.sh mail.taojiang.online
# bash myCertbot.sh mail.gztech.online
