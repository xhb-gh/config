#!/bin/bash

FQDN="mail.gztech.online"
DOMAINNAME="gztech.online"

############################  设置主机名 hostname #######################
cat << EOF > /etc/hostname
$FQDN
EOF

echo "/etc/hosts: "
cat /etc/hosts
#cat << EOF > /etc/hosts
#127.0.0.1	 localhost
## 127.0.1.1  $FQDN mail
#::1		localhost ip6-localhost ip6-loopback
#ff02::1		ip6-allnodes
#ff02::2		ip6-allrouters
#EOF

# 立即应用新的主机名设置，而无需重启系统
hostnamectl set-hostname $FQDN
echo -n "hostname: " && hostname
echo -n "hostname -f (FQDN): " && hostname -f

########################## 启动mailserver容器 ##########################
PASSWORD=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)
# 上传 compose.yaml
wget "https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master/mailserver.env"
docker compose up -d
docker exec -ti mailserver setup email add january@gztech.online ${PASSWORD}
docker exec -ti mailserver setup email add postmaster@gztech.online
docker exec -it mailserver setup alias add postmaster@gztech.online 3096459788@qq.com
docker exec -it mailserver setup email list

###################### DNS记录 数字签名 dkim ##########################
docker exec -ti mailserver setup config dkim
echo "dkim记录"
cat ./docker-data/dms/config/opendkim/keys/${DOMAINNAME}/mail.txt
docker compose down mailserver
echo "添加DNS记录 dkim"

############################# 启动容器 mailserver #############################
docker compose up --build -d
docker exec -it mailserver setup email list
#echo -e "\n" && tail -n 30 ./docker-data/dms/mail-logs/mail.log
echo "username: january, password: ${PASSWORD}"

# 常用命令
# docker ps -a
# docker compose down mailserver
# docker compose up --build -d
# docker logs --tail 30 mailserver
# docker restart mailserver

# docker exec -it mailserver setup
# docker exec -it mailserver cat /etc/dovecot/conf.d/10-master.conf
# docker exec -it mailserver ls /etc/letsencrypt/live
# docker exec -ti mailserver setup email add january@gztech.online ${PASSWORD}
# docker exec -it mailserver setup email update january@gztech.online ${PASSWORD}
# docker exec -it mailserver setup email del january@gztech.online
# 测试SSL
# docker exec mailserver openssl s_client -connect 0.0.0.0:465 -starttls smtp -CApath /etc/letsencrypt/
