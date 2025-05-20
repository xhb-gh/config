#!/bin/bash

# Add Docker's official GPG key:
apt-get update
apt-get install ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install using the apt repository
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
docker run hello-world

docker --version
systemctl start docker
systemctl enable docker
systemctl status docker

# docker images
# docker inspect <image_id>
# docker rmi <image_id>
# docker run -d --name my_container my_image

# 查看所有Docker容器
# docker ps -a
# docker logs <container_id>
# docker rm <container_id>
# docker rm -f $(docker ps -aq) #移除所有容器

# apt remove docker-compose
# apt-get autoremove -y
