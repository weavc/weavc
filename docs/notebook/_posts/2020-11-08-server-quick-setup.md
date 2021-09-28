---
layout: md
title: Quick server setup & security
description: 'Server setup notes & security resources'
tags: ['linux', 'security']
categories: ['linux', 'security']
sort_key: 1
---

{% include project-headers.html %}

#### Script
`bash -c "$(curl -fsSL https://blog.weav.ovh/assets/files/setup.sh)"`

```
sudo apt-get update
sudo apt-get install -y docker.io
sudo adduser chris --disabled-password
sudo usermod -aG sudo chris
sudo usermod -aG docker chris
sudo echo "chris    ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sudo -u chris ssh-keygen -b 2048 -t rsa -f /home/chris/.ssh/id_rsa -q -N ""
sudo -u chris touch /home/chris/.ssh/authorized_keys
sudo -u chris echo "..." > /home/chris/.ssh/authorized_keys
```

#### SSH Changes
```
sudo nano /etc/ssh/sshd_config
... make changes...
sudo systemctl restart sshd
```
Change:
```
PermitRootLogin No
PasswordAuthentication no
```

#### Add SSH IP whitelist
```
iptables -A INPUT -p tcp -s [ip-address] --dport 22 -j ACCEPT
or
sudo ufw allow from [ip-address]/24 to any port 22
```

#### Security Resources (thanks digitalocean)
- [Securing linux VPS](https://www.digitalocean.com/community/tutorials/an-introduction-to-securing-your-linux-vps)
- [SSH 2fa](https://www.digitalocean.com/community/tutorials/how-to-set-up-multi-factor-authentication-for-ssh-on-ubuntu-20-04)
- [UFW Essentials](https://www.digitalocean.com/community/tutorials/ufw-essentials-common-firewall-rules-and-commands)
- [UFW Basics](https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server)
