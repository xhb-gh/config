#!/bin/bash

set -e

if ! command -v ufw >/dev/null 2>&1; then
  echo "ufw 未安装，正在安装..."
  apt-get update
  apt-get install -y ufw
else
  echo "ufw 已安装"
fi

ufw --force reset  # 加 --force 避免交互提示。
ufw --force enable
ufw status numbered

ufw allow 188

# proxy
ufw allow 801
ufw allow 802
ufw allow 8443

# mail
ufw allow 143
ufw allow 993
ufw allow 465
ufw allow 587

# nginx
ufw allow 80
ufw allow 443

ufw status numbered
systemctl restart ufw

#systemctl list-unit-files --type=service | grep enabled
# systemctl list-units --type=service --state=running