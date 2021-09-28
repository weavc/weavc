---
layout: md
title: chrisweaver1.github.io
repo: chrisweaver1/chrisweaver1.github.io
description: Simple, personal website/blog/portfolio built using Jekyll, hosted ny Github Pages
tags: ['jekyll', 'ruby', 'html', 'portfolio', 'docker']
sort_key: 2
---

{% include project-headers.html %}

![Ruby Build](https://github.com/ChrisWeaver1/chrisweaver1.github.io/workflows/Ruby%20Build/badge.svg?branch=master)

My portfolio/personal website and blog built using Jekyll and hosted by Github Pages. I've gone through quite a few iterations of personal websites, starting from when I originally made one in university. This is certainly the one I am most pleased with so far. 

Jekyll allows me to work with a mixture of Markdown, HTML and Liquid templating, making it easy to write for and maintain the website without having to mess about with Javascript or large amounts of HTML, unless I want an entirely new page layout or design. Jekyll allows you to create collections, components/includes and layouts which can be used and then reused throughout the site in a variety of different ways. It will then build up the website into static pages making it extremely easy to host, even for free through services like Github Pages.

I have also set up this repository to use Github actions to produce an Nginx based docker image of the site and push it into their Docker repository, making it extremely easy for me to deploy myself if/when required. 