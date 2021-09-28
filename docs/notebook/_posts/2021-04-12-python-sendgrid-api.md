---
layout: md
title: Send Email via Sendgrids API
description: 
tags: ['python', 'email']
categories: ['python', 'dev', 'tools']
---

{% include project-headers.html %}

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
