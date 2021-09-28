---
layout: md
title: Crusch
repo: weavc/crusch
description: Authenication helper & query library for Githubs JSON API
tags: ['go', 'github', 'bot', 'application', 'api']
sort_key: 2
pinned: true
---

{% include project-headers.html %}

![tests](https://github.com/weavc/crusch/workflows/Go/badge.svg?branch=master) 
[![GoDoc](https://img.shields.io/static/v1?label=godoc&message=reference&color=blue)](https://pkg.go.dev/github.com/weavc/crusch)

Crusch is a lightweight library  which provides tools for Github Apps to communicate with Githubs V3 API, without too much unnecessary hassle.

This library provides a simple client struct to make requests to Githubs API. Clients aid with adding and creating the required authorization headers, renewing them when they to be renewed and other helper methods.

It wasn't made as a replacement for the larger libraries that do similar things (`go-github`), but it was designed as a lightweight client to make things easier for projects that don't need everything that `go-github` offers. I often found myself cross referencing both Githubs API documentation and the `go-github` documentation which often felt over complicated for what I was trying to put together. At the same time handling the authentication for Github applications can get quite complex, having to produce your own JWT token for the provided PEM file, then requesting a very short lived token (10 minutes) from Github for an installation.

#### Usage

Making a request is as simple as:
```go
import "github.com/weavc/crusch"

client := crusch.NewDefault()
client.NewInstallationAuthFile(<ApplicationID>, <InstallationID>, <PEM keyfile location>)

var v []github.Issue{}
respose, err := client.GetJson("/repos/weavc/crusch/issues", 
    "assignee=chrisweaver1&state=open", &v)
```

This will create the necessary authentication headers from the provided Application ID, Installation ID and PEM file, then perform the request to `https://api.github.com/repos/weavc/crusch/issues`. If the request is successful the data will be decoded and bound to `&v` in this case. Any errors and the full response are sent back to the application so they can be handled separately, i.e. Github often sends back additional details in headers like `Link` headers.



