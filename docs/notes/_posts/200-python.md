---
layout: post
title: Python
tags: ['dev']
icon: code-slash
---

## Configuration examples

### Project structure:
```shell
. (root)
├── fir (package)
│   ├── cmd
│   ├── config
│   ├── context.py
│   ├── data
│   ├── types
│   └── utils
├── Makefile
├── poetry.lock
├── pyproject.toml
├── pytest.ini
├── README.md
└── test (tests)
    ├── __init__.py
    └── test_builder.py
```

### Flake8 config `.flake8`
```ini
[flake8]
exclude = .git,__pycache__,docs/source/conf.py,old,build,dist
max-complexity = 10
max-line-length = 125
```

### Pytest `pytest.ini`
```ini
[pytest]
python_files=test_*.py
```

### Poetry package
```toml
[tool.poetry]
name = "weavc-fir"
version = "0.1.0-beta.1"
description = ""
authors = ["weavc <chrisweaver1@pm.me>"]
license = "MIT"
readme = "README.md"
packages = [{include = "fir"}]

[tool.poetry.dependencies]
python = "^3.11"
termcolor = "^2.3.0"
tabulate = "^0.9.0"
shortuuid = "^1.0.11"
tomli-w = "^1.0.0"
marshmallow = "~3.20.1"
argcomplete = "^3.1.6"
python-slugify = "^8.0.1"

[tool.poetry.group.dev.dependencies]
pytest = "^6.0.0"
flake8 = "^6.1.0"
autopep8 = "2.0.4"

[tool.poetry.scripts]
fir = 'fir.cmd:cmd'

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.autopep8]
max_line_length = 120
ignore = "E501,W6"  # or ["E501", "W6"]
in-place = true
recursive = true
aggressive = 3
```

## Extract Images From .har files
```python
#!/usr/bin/env python3
import json
import base64
import os
import sys
import hashlib

with open(sys.argv[1], "r") as f:
    har = json.loads(f.read())

entries = har["log"]["entries"]

for entry in entries:
    mimetype = entry["response"]["content"]["mimeType"]
    if mimetype.startswith('image/') is False:
        continue
    ext = mimetype.split('/')[1]
    b64 = entry["response"]["content"]["text"]
    hash = hashlib.md5('{}'.format(b64).encode()).hexdigest()

    file = os.path.join('.', '{}.{}'.format(hash, ext))
    with open(file, "wb") as f:
        f.write(base64.b64decode(b64))
```

## Sendgrid API Debugging [Python]

Quick send email api request for sendgrid, helps deugging models and requests etc. For actual sendgrid use, use [Sendgrids python client](https://github.com/sendgrid/sendgrid-python).

```python
import requests

to = ''
from = ''
subject = 'Debug email'
content = 'Test email'
apiKey = ''

body = {
   "personalizations": [
      {
        "to": [
            { 
                "email":to 
            }
        ]
      }
   ],
   "from" : {
      "email" : from
   },
   "subject" : subject,
   "content" : [
      {
         "type": "text/html",
         "value": content
      }
   ]
}

session = requests.Session()
session.headers.update({ 'Content-Type': 'application/json' })
session.headers.update({ 'Authorization': 'Bearer ' + apiKey })

res = session.post('https://api.sendgrid.com/v3/mail/send', json=body)

print(res)
print(res.text)
```

## SMTP Debug Tool [Python]

```python
import smtplib, ssl
import poplib, ssl
from email.message import EmailMessage

port = 465  # For SSL
server = ''
password = ''
email = ''
to = ''

# Create a secure SSL context
context = ssl.create_default_context()
msg = EmailMessage()
msg.set_content('helo, this is a debug email')
msg['Subject'] = 'debugging email'
msg['To'] = to
msg['From'] = email

with smtplib.SMTP_SSL(server, port, context=context) as server:
    server.set_debuglevel(2)
    res = server.login(email, password)
    print(res)
    res = server.send_message(msg)
    print(res)
```