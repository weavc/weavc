---
layout: post
title: Linux
tags: ['linux', 'server', 'devops']
icon: terminal
---

## Useful Makefile

```shell
# ======== Variables ==========
VERSIONS_GO := 1.21.8
VERSIONS_PYTHON := 3
VERSIONS_DOTNET := 8.0
VERSIONS_NODE := 18
VERSIONS_NVM := 0.39.7

PATHS_GO = $$HOME/.local
PATHS_GOHOME = $$HOME/dev/go
PATHS_DOTNET = $$HOME/.local
PATHS_CARGO = $$HOME/.cargo

PATH_VAR = $HOME/.local/bin /opt/bin ${PATHS_CARGO}/bin ${PATHS_DOTNET}/dotnet ${PATHS_GO}/go/bin ${PATHS_GOHOME}/bin $HOME/.cargo/bin

# ======== Utility ==========

## help: Prints this help message.
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## help/install: Prints help message for install commands.
.PHONY: help/install
help/install:
	@echo 'Usage:'
	@sed -n 's/^## install\///p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## help/sshgen: Prints help message for sshgen commands.
.PHONY: help/sshgen
help/sshgen:
	@echo 'Usage:'
	@sed -n 's/^## sshgen\///p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## help/setup: Prints help message for setup commands.
.PHONY: help/setup
help/setup:
	@echo 'Usage:'
	@sed -n 's/^## setup\///p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

## mkdirs: Creates default directories.
.PHONY: mkdirs
mkdirs: mkdirs/dev

## mkdirs/dev: Creates default dev directories
.PHONY: mkdirs/dev
mkdirs/dev:
	mkdir -p $$HOME/dev/proj $$HOME/dev/misc $$HOME/dev/builds $$HOME/dev/envs

# ======== Setup ==========

## setup: Setup script for general ubuntu environments.
.PHONY: setup
setup: mkdirs sshgen/auth sshgen/ed25519 install/basics install/fish install/docker install/python install/dotnet install/go install/vscode dotfiles/apply

## setup/wsl: Setup script for WSL environments.
.PHONY: setup/wsl
setup/wsl: mkdirs sshgen/auth sshgen/rsa sshgen/ed25519 install/basics install/fish install/docker install/python install/dotnet dotfiles/apply

## setup/server: Setup script for headless/server environments.
.PHONY: setup/server/tmp/go-install-make.tar.gz
setup/server: mkdirs sshgen/auth sshgen/ed25519 install/basics install/fish install/docker install/python dotfiles/apply

# ======== Dotfiles ==========

## dotfiles/apply: Apply the dotfiles using stow.
.PHONY: dotfiles/apply
dotfiles/apply:
	stow -S dotfiles -d ./ -t $$HOME/

# ======== Dev tools ==========

## install/basics: Installs basic utilities and tools.
.PHONY: install/basics
install/basics:
	sudo apt install -y make curl stow wget apt-transport-https gpg

## install/docker: Installs docker tools.
.PHONY: install/docker
install/docker:
	sudo apt install -y docker.io docker-compose
	sudo usermod -g docker $$(whoami)

## install/fish: Installs fish.
.PHONY: install/fish
install/fish:
	sudo add-apt-repository ppa:fish-shell/release-3 -y
	sudo apt update
	sudo apt install -y fish
	chsh -s /usr/bin/fish
	curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher

## install/python: Installs python.
.PHONY: install/python
install/python:
	sudo apt install -y python${VERSIONS_PYTHON} python3-pip

## install/dotnet: Installs dotnet SDK.
.PHONY: install/dotnet
install/dotnet:
	curl -L -o /tmp/dotnet-install-make.sh https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh
	chmod u+x /tmp/dotnet-install-make.sh
	/tmp/dotnet-install-make.sh --channel ${VERSIONS_DOTNET} --install-dir ${PATHS_DOTNET}/dotnet --os linux

## install/go: Installs go.
.PHONY: install/go
install/go:
	curl -L -o /tmp/go-install-make.tar.gz https://go.dev/dl/go${VERSIONS_GO}.linux-amd64.tar.gz
	rm -rf ${PATHS_GO}/go ${PATHS_GOHOME}  
	mkdir -p ${PATHS_GO}
	tar -xvzf /tmp/go-install-make.tar.gz -C ${PATHS_GO}
	mkdir -p ${PATHS_GOHOME}/src ${PATHS_GOHOME}/bin

## install/vscode: Installs vscode.
.PHONY: install/vscode
install/vscode:
	wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
	sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
	sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
	rm -f packages.microsoft.gpg
	sudo apt update
	sudo apt install code

## install/nvm: Install NVM.
install/nvm:
	mkdir -p $$HOME/.nvm
	rm -rf $$HOME/.nvm/*
	curl -L -o /tmp/nvm-installer-make.sh https://raw.githubusercontent.com/nvm-sh/nvm/v${VERSIONS_NVM}/install.sh
	chmod u+x /tmp/nvm-installer-make.sh
	NODE_VERSION=${VERSIONS_NODE} /tmp/nvm-installer-make.sh

# ======== SSH Keygen ==========

## sshgen: Create ssh keys.
.PHONY: sshgen
sshgen: sshgen/ed25519

## sshgen/rsa: Create RSA ssh keys.
.PHONY: sshgen/rsa
sshgen/rsa:
	ssh-keygen -t rsa -C "$$(whoami)@$$(hostname -s)"

## sshgen/rsa: Create ed25519 ssh keys.
.PHONY: sshgen/ed25519
sshgen/ed25519:
	ssh-keygen -t ed25519 -C "$$(whoami)@$$(hostname -s)"

## sshgen/auth: Import authorized keys from github.
.PHONY: sshgen/auth
sshgen/auth:
	ssh-import-id gh:weavc
```

## Cloud init
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

## Setting up a persistant ssh tunnel to a firewalled server

### Tunnel

```shell
ssh -g -N -T -o "ExitOnForwardFailure yes" -o "ServerAliveInterval 60" -R <listen on ip>:<listen on port>:localhost:22 <user>@<domain>
```

### sshd_config
```shell
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

## Yubikey configuration

Yubikey setup, resources and guides

### Useful Commands

Note: You often have to configure the yubikey do allow certain behaviours and create/setup pins and security credentials before running these commands. All of that can be done with yubikey-manager or `ykman`.

Install packages:
```
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

### Resources

- [GPG Setup 1](https://www.barrage.net/blog/technology/yubikey-and-gpg)
- [GPG Setup 2](https://developers.yubico.com/PGP/PGP_Walk-Through.html)

## OpenSSL commands for generating RSA key pair
Used in Jwt and other similar things.
```shell
openssl genrsa -out <path>/privkey.pem 4096 && \
openssl rsa -in <path>/privkey.pem -pubout > <path>/pubkey.pem
```

## Samba Network Share on Raspberry Pi

Using [`alexandreroman/rpi-samba`](https://github.com/alexandreroman/rpi-samba)

### Create a directory for the share
```
mkdir [path-to-share]
```
- This will be bind mounted to the docker container

### Clone the repo & build the image
```
git clone https://github.com/alexandreroman/rpi-samba.git
cd rpi-samba
make
```

### Run
```
docker run -d -it --name samba --restart=unless-stopped -v [path-to-share]:/data/share -p 445:445 rpi-samba
```

## Luks / Cryptsetup Encrypted USB

### Picking a cipher, mode, hash and key size
- Keysize, size does matter here...
- Whats available & best depends on the system and use case
- See `/proc/crypto` & `cryptsetup benchmark` for ciphers available 
- See `cryptsetup --help | tail -n 8` for defaults. Should be "Pretty good"
- Further Reading: 
  - [https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf)
  - [https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks](https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks)
  - [https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size](https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size)
- Useful extract:
> ### Valid cipher names
>```
>    aes Advanced Encryption Standard - FIPS PUB 197
>    twofish Twofish: A 128-Bit Block Cipher - https://www.schneier.com/paper-twofish-paper.html
>    serpent https://www.cl.cam.ac.uk/~rja14/serpent.html
>    cast5 RFC 2144
>    cast6 RFC 2612
>```
> ### Valid cipher modes
>```
>    ecb The cipher output is used directly.
>    cbc-plain The cipher is operated in CBC mode. 
>    cbc-essiv:{hash}
>    xts-plain64 plain64 is 64-bit version of plain initial vector
>```
> ### Valid hash specifications
>```
>    sha1 RFC 3174 - US Secure Hash Algorithm 1 (SHA1)
>    sha256 SHA variant according to FIPS 180-2
>    sha512 SHA variant according to FIPS 180-2
>    ripemd160 http://www.esat.kuleuven.ac.be/~bosselae/ripemd160.html
>```

I ended up going with `aes-xts-plain64`.

### Find where usb is mounted
```bash
fdisk -h

...

Disk /dev/sdb: 29.45 GiB, 31609323520 bytes, 61736960 sectors
Disk model: Mass-Storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

### Wipe the device
```bash
umount [/dev/sdb]
wipefs -a [/dev/sdb]
```

### Encrpyt the device
```
cryptsetup -y --cipher [cipher] --key-size [keysize] luksFormat [/dev/sdb]
```
Will be prompted for the password here

### Open
```
cryptsetup luksOpen [/dev/sdb] [some-volume-name]
```

### Format
```
sudo mkfs.ext4 /dev/mapper/[some-volume-name] -L [some-volume-name]
```

### Close
```
cryptsetup luksClose [volume-name]
```

