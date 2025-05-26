#!/usr/bin/env bash
# Linux 系统清理脚本

set -e # 适合部署脚本；比如清理、安装、修改系统时，一旦出错立刻停止

get_disk_stats() {
  df -BG --total | awk '
    BEGIN { total=0; used=0; avail=0 }
    /^\/dev\// {
      sub("G", "", $2); sub("G", "", $3); sub("G", "", $4)
      total += $2; used += $3; avail += $4
    }
    END { print total, used, avail }
  '
}
read total_before used_before avail_before <<< $(get_disk_stats)

echo "正在清理 Linux 系统垃圾文件..."
# 1. 清理 APT 缓存
echo "清理 apt 缓存..."
sudo apt-get autoremove -y
sudo apt-get autoclean -y
sudo apt-get clean

# 2. 清理日志文件（按需）
echo "清理 /var/log 中的旧日志..."
sudo find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

# 3. 清理临时文件
echo "清理 /tmp 和 /var/tmp 中的临时文件..."
sudo rm -rf /tmp/*
sudo rm -rf /var/tmp/*

# 4. 清理废弃软件包
echo "移除孤立软件包..."
sudo deborphan | xargs sudo apt-get -y remove --purge || true

# 5. 清理 systemd journal 日志（如 journald 使用）
echo "清理 journalctl 日志..."
sudo journalctl --vacuum-time=3d

# 6. 清理 Docker 镜像、容器等（可选）
if command -v docker &> /dev/null; then  # 检测 docker 命令是否存在（即是否安装了 Docker）
  echo "清理 Docker..."
  docker system prune -af --volumes  # 清除未使用的容器、网络、镜像、--volumes 挂载卷等
fi

# 7. 清理用户级缓存
echo "清理用户缓存 ~/.cache ..."
rm -rf ~/.cache/thumbnails/*
rm -rf ~/.cache/*

echo "✅ 清理完成！"

# 记录清理后磁盘使用情况
read total_after used_after avail_after <<< $(get_disk_stats)

echo "清理前后磁盘使用情况（单位：GB）："
{
  echo -e "\t总容量\t已使用\t可用"
  echo -e "清理前\t${total_before}G\t${used_before}G\t${avail_before}G"
  echo -e "清理后\t${total_after}G\t${used_after}G\t${avail_after}G"
} | column -t -s $'\t'
