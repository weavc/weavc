---
layout: post
title: Servers
tags: ['devops', 'server', 'cloud']
icon: server
---

### File Servers
Basic file server:
```bash
python3 -m http.server
```

Updog (Slightly better file server):
```bash
pip3 install updog
updog [-d DIRECTORY] [-p PORT] [--password PASSWORD] [--ssl]

updog -d . -p 8080 --ssl
```


### Dev servers

Flask:
```python
import flask

app = flask.Flask(__name__)

@app.route('/', methods=['GET'])
def index():
    return 'hello world'

app.run(host='0.0.0.0', port=8080)
```

Go & Gorilla Mux
```go
package main

import (
	"net/http"

	"github.com/gorilla/mux"
)

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/", func(rw http.ResponseWriter, r *http.Request) {
		rw.Write([]byte("Hello World"))
		rw.WriteHeader(200)
	})

	http.ListenAndServe("0.0.0.0:8080", r)
}
```


### Docker

Nginx:
```bash
docker run -it --rm -p 8080:80 nginx
docker run -it --rm -p 8080:80 -v <path_to_local_config>:/etc/nginx/nginx.conf:ro -v <path_to_local_website_files>:/usr/share/nginx/html:ro nginx
```


### Wildcard SSL With Certbot / LetsEncrypt

#### Install certbot & dns plugin
```
pip3 install certbot
pip3 install certbot-dns-ovh
```
add `~/.local/bin` to path if its not already

#### OVH App
Create new app: https://eu.api.ovh.com/createApp/

Generate consumer key:
```
curl -XPOST -H"X-Ovh-Application: <application key>" -H "Content-type: application/json" https://eu.api.ovh.com/1.0/auth/credential -d '{"accessRules": [{"method": "POST","path": "/domain/zone/*"},{"method": "DELETE","path": "/domain/zone/*"},{"method": "GET","path": "/domain/zone/*"},{"method": "PUT","path": "/domain/zone/*"}]}'
```

It will return something like:
```
{"validationUrl":"https://eu.api.ovh.com/auth/?credentialToken=<a token>","state":"pendingValidation","consumerKey":"4lzKpYkPux91wLi434DVdkyj7WLHDyvp"}
```
Go to the validation URL and login

Add everything to a file with a template similar to below
```
# OVH API credentials used by Certbot
dns_ovh_endpoint = ovh-eu
dns_ovh_application_key = 
dns_ovh_application_secret = 
dns_ovh_consumer_key = 
```
Then `chmod 600 <file>`.

#### Generate SSL Certs
note: remove 'staging' from the server url for a production run
```
sudo certbot certonly -n --dns-ovh --dns-ovh-credentials <path-to-credentials> --server https://acme-staging-v02.api.letsencrypt.org/directory -d <domain>,<*.domain> --email <emai> --agree-tos
```

optional:
```
--work-dir <path-to-work-dir>
--logs-dir <path-to-logs-dir>
--config-dir <path-to-config-dir>
```