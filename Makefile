
dotfiles:
	tar -C dotfiles/ -cf - . | tar -C ~ --skip-old-files -xf -

install-basics:
	sudo apt install -y make curl docker.io docker-compose

install-omb:
	bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)";

install-ansible:
	pip3 install ansible docker

setup-pop:
	ansible-playbook -K ./playbooks/pop_os/setup.yml --extra-vars '@playbooks/pop_os/vars/20220716_vars.yml'