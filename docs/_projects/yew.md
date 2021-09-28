---
layout: md
title: Yew
repo: weavc/yew
description: Lightweight plugin manager for Go. Implement and communicate with go plugins
tags: ['go', 'plugins', 'events']
sort_key: 1
pinned: true
---

{% include project-headers.html %}

![tests](https://github.com/weavc/yew/workflows/Go/badge.svg?branch=master) 
[![GoDoc](https://img.shields.io/static/v1?label=godoc&message=reference&color=blue)](https://pkg.go.dev/github.com/weavc/yew)

Yew is a lightweight module mostly in its development/testing phase. Its aim is to aid in using plugin/event driven architecture within go. There are probably alternatives out there, I just started doing something small and it turned into this.

There are 2 main parts to this module, the `Plugin` and `Handler`. The `Handler` can register any `Plugin`'s it is asked to load, this can be through `.so` file(s) (built using `go build -buildmode=plugin`) or any struct that implements the `pkg/plugin.Plugin` interface, example of this [here](#Plugins).

Plugins can also be extended further by implementing interfaces from other packages. Other packages can then use the handlers `.Walk` method to walk through each of the plugins and see if they have implemented the interface. Below is an example of what this looks like in practice, where plugins can extend anothers server api. This can also be used to share channels and all sorts of information between plugins and the application hosting them.

```go
type RegisterAPI interface {
  RegisterRoutes(mux *http.ServeMux)
}

...

var s *http.ServeMux = http.DefaultServeMux

handler.Walk(func(man *plugin.Manifest, plgin plugin.Plugin) {
  // check if plugin implements RegisterAPI interface
  p, e := plgin.(RegisterAPI)
  if e == true {
    // let plugin register handlers
    p.RegisterRoutes(s)
  }
})
```
 
