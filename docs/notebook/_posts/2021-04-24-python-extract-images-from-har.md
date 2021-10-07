---
layout: post
title: Extract Images From .har files [Python]
description: Small script to extract images from .har files
tags: ['python', 'images']
terms: ['python', 'dev', 'tools']
icon: tools
---

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
