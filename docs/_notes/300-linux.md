---
layout: post
title: Linux
tags: ['linux', 'server', 'devops']
icon: terminal
---

{% include notes.html set="linux" %}

### Cloud init

note: The #cloud-config is required.

```yaml
#cloud-config
users:
  - default
  - name: chris
    groups: [docker, sudo]
    ssh_import_id:
      - gh:weavc
    lock_passwd: true
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash

package_update: true
package_upgrade: true
packages:
 - docker.io
 - docker-compose
```


### Setting up a persistant ssh tunnel to a firewalled server

#### Tunnel

```shell
ssh -g -N -T -o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" -R <listen on ip>:<listen on port>:localhost:22 <user>@<domain>
```

#### sshd_config
```shell
GatewayPorts yes
```

#### `systemd`
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


### Yubikey configuration

Yubikey setup, resources and guides

#### Useful Commands

Note: You often have to configure the yubikey do allow certain behaviours and create/setup pins and security credentials before running these commands. All of that can be done with yubikey-manager or `ykman`.

Install packages:
```shell
sudo apt-add-repository ppa:yubico/stable
sudo apt install yubikey-manager libfido2-dev gnupg pcscd scdaemon -y
```

Git config signing:
```bash
git config --global user.email "weavc@pm.me"
git config --global user.name "weavc"
git config --global user.signingkey 04FE6CA73DB1B038
git config --global gpg.program gpg
git config --global commit.gpgsign true
```

SSH Resident key:
```bash
Generate new key:
ssh-keygen -t ed25519-sk -O resident -C "weavc@pm.me"

Add from device to keychain:
ssh-add -K

Get local files from key (for backups or common use):
ssh-keygen -K
```

Import Public GPG key:
```bash
curl -fsSL http://www.weav.ovh/weavc@pm.me_pub.gpg | gpg --import
```

#### Resources

- [GPG Setup 1](https://www.barrage.net/blog/technology/yubikey-and-gpg)
- [GPG Setup 2](https://developers.yubico.com/PGP/PGP_Walk-Through.html)


### OpenSSL commands for generating RSA key pair
Used in Jwt and other similar things.
```shell
openssl genrsa -out <path>/privkey.pem 4096 && \
openssl rsa -in <path>/privkey.pem -pubout > <path>/pubkey.pem
```


### Samba Network Share on Raspberry Pi

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


### Luks / Cryptsetup Encrypted USB

#### Picking a cipher, mode, hash and key size
- Keysize, size does matter here...
- Whats available & best depends on the system and use case
- See `/proc/crypto` & `cryptsetup benchmark` for ciphers available 
- See `cryptsetup --help | tail -n 8` for defaults. Should be "Pretty good"
- Further Reading: 
  - [https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf)
  - [https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks](https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks)
  - [https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size](https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size)
- Useful extract:
> #### Valid cipher names
>```
>    aes Advanced Encryption Standard - FIPS PUB 197
>    twofish Twofish: A 128-Bit Block Cipher - https://www.schneier.com/paper-twofish-paper.html
>    serpent https://www.cl.cam.ac.uk/~rja14/serpent.html
>    cast5 RFC 2144
>    cast6 RFC 2612
>```
> #### Valid cipher modes
>```
>    ecb The cipher output is used directly.
>    cbc-plain The cipher is operated in CBC mode. 
>    cbc-essiv:{hash}
>    xts-plain64 plain64 is 64-bit version of plain initial vector
>```
> #### Valid hash specifications
>```
>    sha1 RFC 3174 - US Secure Hash Algorithm 1 (SHA1)
>    sha256 SHA variant according to FIPS 180-2
>    sha512 SHA variant according to FIPS 180-2
>    ripemd160 http://www.esat.kuleuven.ac.be/~bosselae/ripemd160.html
>```

I ended up going with `aes-xts-plain64`.

#### Find where usb is mounted
```bash
fdisk -h

...

Disk /dev/sdb: 29.45 GiB, 31609323520 bytes, 61736960 sectors
Disk model: Mass-Storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

#### Wipe the device
```bash
umount [/dev/sdb]
wipefs -a [/dev/sdb]
```

#### Encrpyt the device
```
cryptsetup -y --cipher [cipher] --key-size [keysize] luksFormat [/dev/sdb]
```
Will be prompted for the password here

#### Open
```
cryptsetup luksOpen [/dev/sdb] [some-volume-name]
```

#### Format
```
sudo mkfs.ext4 /dev/mapper/[some-volume-name] -L [some-volume-name]
```

#### Close
```
cryptsetup luksClose [volume-name]
```

