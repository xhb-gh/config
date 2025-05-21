### 一键脚本安装xray

wget -qO- https://raw.githubusercontent.com/xuhuabao/config/main/xrayInstall.sh | bash
 
port，uuid，privateKey，shordIds，public-key

### 一键脚本安装hysteria2

wget -qO- https://raw.githubusercontent.com/xuhuabao/config/main/hysteria2Install.sh | bash

### docker安装 navidrome
docker run -d  --name navidrome --restart=unless-stopped  \
--user $(id -u):$(id -g)  -v /root/navidrome/music:/music   \
-v /root/navidrome/data:/data  -p 4533:4533   \
-e ND_LOGLEVEL=info  -e ND_BASEURL="/music"  deluan/navidrome:latest
