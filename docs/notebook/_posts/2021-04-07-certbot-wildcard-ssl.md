---
layout: md
title: Wildcard SSL with certbot
description: 'Generating wildcare SSL with certbot & ovh dns'
sort_key: 1
tags: ['misc', 'security', 'tls']
categories: ['security', 'linux']
---

{% include project-headers.html %}

### Install certbot & dns plugin
```
pip3 install certbot
pip3 install certbot-dns-ovh
```
add `~/.local/bin` to path if its not already

### OVH App
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

