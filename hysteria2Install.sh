#!/bin/bash

set -e
if ps aux | grep -v grep | grep hysteria; then
  echo "Hysteria 已在运行"
  exit 1
fi

bash <(curl -fsSL https://get.hy2.sh/)

#生成自签名证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
-subj "/CN=bing.com" -days 36500 && chown hysteria /etc/hysteria/server.key && chown hysteria /etc/hysteria/server.crt

PW=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)


echo "修改配置文件 /etc/hysteria/config.yaml"
cat << EOF > /etc/hysteria/config.yaml
listen: :802

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $PW

masquerade:
  type: proxy
  proxy:
    url: https://bing.com/
    rewriteHost: true
EOF

# 带颜色显示配置文件 /etc/hysteria/config.yaml
printf "\n"
grep --color=always -E "^(.*)$" /etc/hysteria/config.yaml
printf "\n"

systemctl start hysteria-server
systemctl enable hysteria-server  # 设置开机自启
systemctl status hysteria-server
#systemctl restart hysteria-server
#systemctl is-active nginx
