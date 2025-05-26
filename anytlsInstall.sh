#!/bin/bash

set -e
# 获取最新版本号
latest_version=$(wget -qO- https://api.github.com/repos/anytls/anytls-go/releases/latest | jq -r .tag_name)

# 构造下载链接
download_url="https://github.com/anytls/anytls-go/releases/download/${latest_version}/anytls_${latest_version#v}_linux_amd64.zip"

# 输出下载信息
echo "Latest version: $latest_version"
echo "Downloading from: $download_url"

# 下载文件
wget -O anytls.zip "$download_url"

# 解压并赋予可执行权限
unzip -o anytls.zip
chmod +x anytls-server

echo "AnyTLS $latest_version 下载完成。"
rm -rf anytls-client readme.md anytls.zip

random_pass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 8)
nohup ./anytls-server -l 0.0.0.0:8443 -p "$random_pass" > /dev/null 2>&1 &

printf "\n"
echo "anytls 监听地址：0.0.0.0:8443"
echo "anytls 随机密码：$random_pass"
printf "\n"
