## OpenVPN

Docs and scripts for basic OpenVPN tasks:
- Service to connect on startup of device
- Docker to setup an OpenVPN server

### Usage

#### Docker:
Passing in the variables each time, use the following commands in order. This will walk you through the configuration setup, start the OpenVPN service and walk you through generating your first authentication certificate. 
```
make <config|start|cert> [addr=<public address>|client=<client name>|data=<data directory>]
```

For more advanced setup and configuration see then image documentation [`kylemanna/openvpn`](https://github.com/kylemanna/docker-openvpn).

#### Service:
Update variables at the top of the `ovpn` file.
```
make <update-rc|rm-rc>
```