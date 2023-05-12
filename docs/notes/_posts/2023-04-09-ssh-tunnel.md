---
layout: post
title: Setting up a persistant ssh tunnel to a firewalled server
description: Setting up a persistant ssh tunnel to a firewalled server
tags: ['linux', 'server']
terms: ['linux']
icon: hdd-network
sort_key: 1
---

### Tunnel

```bash
ssh -g -N -T -o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" -R <listen on ip>:<listen on port>:localhost:22 <user>@<domain>
```

### sshd_config
```
GatewayPorts yes
```

### `systemd`
```ini
[Unit]
Description=SSH Tunnel
After=network.target

[Service]
Restart=always
RestartSec=20
User=<user>
ExecStart=/usr/bin/ssh -g -N -T -o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" -R <listen on ip>:<listen on port>:localhost:22 <user>@<domain>

[Install]
WantedBy=multi-user.target
```
