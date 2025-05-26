#!/bin/bash

set -e

if ps aux | grep -v grep | grep xray; then
  echo "xray 已在运行"
  exit 1
fi

# 安装
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# 卸载
# bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove

xray uuid > myuuid
xray x25519 > mykey

UUID=$(cat myuuid)
Private_Key=$(grep "Private key:" mykey | awk -F"Private key: " '{print $2}' | xargs)

echo "修改配置文件"
echo "/usr/local/etc/xray/config.json"
jq -C '.inbounds[0]' /usr/local/etc/xray/config.json

wget "https://raw.githubusercontent.com/xhb-gh/config/main/xray_server_config.json"
json_origin="./xray_server_config.json"

jq --arg id "${UUID}" --arg key "${Private_Key}" \
   '.inbounds[0].settings.clients[0].id = $id |
    .inbounds[0].streamSettings.realitySettings.privateKey = $key' \
   "$json_origin" > /usr/local/etc/xray/config.json

jq -C '.inbounds[0]' /usr/local/etc/xray/config.json

#printf "\e[31m这是红色文字\e[0m\n"
#printf "\e[34m这是蓝色文字\e[0m\n"
printf "\e[31m xray vless uuid:\n%s\n \e[0m\n" "$(cat myuuid)"
printf "\e[31m xray vless key:\n%s\n \e[0m\n" "$(cat mykey)"


systemctl enable xray
systemctl status xray
# cp ./vpn/xray_server_config.json /usr/local/etc/xray/config.json
systemctl restart xray
