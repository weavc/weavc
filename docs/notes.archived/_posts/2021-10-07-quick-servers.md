---
layout: post
title: Quick and easy servers
tags: ['nginx', 'docker', 'python', 'go']
terms: ['docker', 'dev']
icon: diagram-2
---

#### File Servers
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

#### Dev servers

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

#### Docker

Nginx:
```bash
docker run -it --rm -p 8080:80 nginx
docker run -it --rm -p 8080:80 -v <path_to_local_config>:/etc/nginx/nginx.conf:ro -v <path_to_local_website_files>:/usr/share/nginx/html:ro nginx
```