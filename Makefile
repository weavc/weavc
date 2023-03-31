install-ansible:
	pip3 install ansible docker

install-pop:
	ansible-playbook -K ./playbooks/pop_os/setup.yml --extra-vars '@playbooks/pop_os/vars/20220716_vars.yml'