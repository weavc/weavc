---
layout: md
title: Python SMTP debugging
description: Quick script to help debug SMTP issues
tags: ['python', 'smtp']
categories: ['python', 'dev', 'tools']
---

{% include project-headers.html %}

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
