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
	stow -S files -d ./ -t $$HOME/

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

## install/fish: Installs fish.
.PHONY: install/fish
install/fisher:
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
