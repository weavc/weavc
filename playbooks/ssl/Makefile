local:
	ansible-playbook generate_ssl_locally.yml --ask-vault-pass -K

distribute:
	ansible-playbook distribute_ssl.yml -K -i ./vars/hosts.ini