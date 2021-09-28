---
layout: md
title: Misc docker stuff
description: 'Random docker commands that occasionally come in handy'
tags: ['docker']
categories: ['docker']
sort_key: 0
---

{% include project-headers.html %}

##### Services/Swarms examples
```
docker swarm init
docker network create --driver overlay my-network
```
```
docker service create \
    --mount type=bind,src=<path-to-certs>/fullchain.pem,dst=/certs/fullchain.pem,ro \
    --mount type=bind,src=<path-to-certs>/privkey.pem,dst=/certs/privkey.pem,ro \
    --mount type=bind,src=<path-to-site-defs>,dst=/sites \
    --publish 80:80 \
    --publish 443:443 \
    --replicas 3 \
    --name weavc-nginx \
    --network=<network> \
    docker.pkg.github.com/weavc/weavc-nginx/weavc-nginx:latest
```
```
docker service create \
    --replicas 3 \
    --name <name> \
    --network=<network> \
    <image>:latest
```
- [service docs](https://docs.docker.com/engine/reference/commandline/service/)
- [swarm/services docs](https://docs.docker.com/engine/swarm/services/)

##### Images
- [linuxserver](https://hub.docker.com/u/linuxserver)

##### [Portainer](https://hub.docker.com/r/portainer/portainer)
```
docker run --name portainer --network=netty -d -v /var/run/docker.sock:/var/run/docker.sock -v [data-volume]:/data portainer/portainer
```

##### [Deluge](https://hub.docker.com/r/linuxserver/deluge)
```
docker run \
  --name=deluge \
  --net=host \
  -d \
  -it \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=timezone \
  -e UMASK_SET=022 `#optional` \
  -e DELUGE_LOGLEVEL=error `#optional` \
  -v [config-volume]:/config \
  -v [downloads-volume]:/downloads \
  -v [data-volume]:/data \
  -v [seedbox-volume]:/seedbox \
  --restart unless-stopped \
  linuxserver/deluge
```
