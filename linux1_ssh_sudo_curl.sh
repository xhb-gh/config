#!/bin/sh
set -e
#printf "\e[31m这是红色文字\e[0m\n"
#printf "\e[34m这是蓝色文字\e[0m\n"

# ssh端口, Port 22, #Port 22
echo "将原始ssh端口22改为188"
sed -i 's/^#\?Port[[:space:]]\+22/Port 188/' /etc/ssh/sshd_config
systemctl restart sshd
ss -tuln

# 终端提示符颜色
cat << EOF > /root/.bashrc
PS1='[\[\e[31m\]\u@\h\[\e[0m\]|\[\e[34m\]\w \[\e[0m\]]#: '
EOF
. /root/.bashrc
# source /root/.bashrc

echo "安装sudo命令"
dpkg -s sudo >/dev/null 2>&1 || apt-get install -y sudo

REQUIRED_CMDS="curl wget unzip jq"
MISSING=""
echo "检查每个命令是否存在 $REQUIRED_CMDS"

# 检查每个命令是否存在
for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "未安装: $cmd"
        MISSING="$MISSING $cmd"
    else
        echo "已安装: $cmd"
    fi
done

# 如果有缺失的，安装
if [ -n "$MISSING" ]; then
    # 去除前导空格
    MISSING="$(echo $MISSING | xargs)"
    echo "正在安装缺失的软件包: $MISSING"
    sudo apt-get update
    sudo apt-get install -y $MISSING
else
    echo "所有必需软件包均已安装 ✅"
fi