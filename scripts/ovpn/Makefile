usage:
	echo "make <config|start|cert> [addr=<public address>|client=<client name>|data=<data directory>]"

config:
	docker run -v $(data):/etc/openvpn --rm kylemanna/openvpn ovpn_genconfig -u udp://$(addr) && \
	docker run -v $(data):/etc/openvpn --rm -it kylemanna/openvpn ovpn_initpki

start:
	docker run -v $(data):/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

cert:
	docker run -v $(data):/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full $(client) nopass

update-rc:
	@sudo cp ./ovpn /etc/init.d/ && \
	sudo update-rc.d ovpn defaults

rm-rc:
	@sudo update-rc.d ovpn remove && \
	sudo rm /etc/init.d/ovpn

check-ip:
	@curl ipecho.net/plain && echo "\n"