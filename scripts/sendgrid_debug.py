#!/usr/bin/env python3
import requests

to = ''
from_ = ''
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
      "email" : from_
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
