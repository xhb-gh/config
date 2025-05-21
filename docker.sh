# navidrome
docker run -d  --name navidrome --restart=unless-stopped  \
--user $(id -u):$(id -g)  -v /root/navidrome/music:/music   \
-v /root/navidrome/data:/data  -p 4533:4533   \
-e ND_LOGLEVEL=info  -e ND_BASEURL="/music"  deluan/navidrome:latest
