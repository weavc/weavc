---
layout: md
title: ngx-youtube-embed
repo: chrisweaver1/ngx-youtube-embed
description: Component for embeding Youtube videos into Angular projects
tags: ['angular', 'npm', 'html', 'typescript']
sort_key: 2
---

{% include project-headers.html %}

[![npm version](https://badge.fury.io/js/ngx-youtube-embed.svg)](https://badge.fury.io/js/ngx-youtube-embed)
![npm publish](https://github.com/ChrisWeaver1/ngx-youtube-embed/workflows/npm%20publish/badge.svg?branch=master&event=release)
![node build and test](https://github.com/ChrisWeaver1/ngx-youtube-embed/workflows/node%20build%20and%20test/badge.svg)


An Angular component that allows the embedding of youtube videos into an angular webpage. Options and event hooks can be passed through to the component so the user can fully utilize [Youtube's embed/iframe api](https://developers.google.com/youtube/iframe_api_reference). 

```html
<youtube-embed [videoId]="id" width="1280" height="720" (ready)="savePlayer($event)"
        (change)="onStateChange($event)" [protocol]="'https'" 
        [playerVars]="{ controls: 1, showinfo: 0, rel: 0, autoplay: 1, modestbranding: 0 }">
</youtube-embed>
```

This was a small project for something we were doing at work as nothing really met our requirements at the time. I decided to put this together, using parts from other projects and packaged it up for internal use, later making it public. 