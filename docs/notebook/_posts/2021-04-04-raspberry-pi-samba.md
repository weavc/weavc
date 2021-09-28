---
layout: md
title: Samba share on Raspberry Pi using docker
description: 'Quick setup for using samba on a Raspberry Pi with docker'
tags: ['docker', 'raspberry pi', 'samba']
categories: ['linux', 'docker']
sort_key: 1
---

{% include project-headers.html %}

Using [`alexandreroman/rpi-samba`](https://github.com/alexandreroman/rpi-samba)

#### Create a directory for the share
```
mkdir [path-to-share]
```
- This will be bind mounted to the docker container

#### Clone the repo & build the image
```
git clone https://github.com/alexandreroman/rpi-samba.git
cd rpi-samba
make
```

#### Run
```
docker run -d -it --name samba --restart=unless-stopped -v [path-to-share]:/data/share -p 445:445 rpi-samba
```
