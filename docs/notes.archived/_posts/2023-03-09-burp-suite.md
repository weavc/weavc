---
layout: post
title: Burp Suite
tags: ['networking', 'security']
terms: ['security']
icon: shield-lock
---

### Burp Suite

#### Proxy
- Proxy and modify requests as they go to the server
- You can also modify the result

#### Repeater
- Repeat & modify requests from Proxy

#### Intruder
Modify requests using wordlists etc
Can use macros to forward parameters, cookies and values between requests (i.e. session cookies, csrf tokens)
- Sniper
    - For targetting a single position with a single wordlist
    - multiple positions can be targetted and it would run them in turn but unlikely to need this
- Battering ram
    - Same as sniper but iterates over each position with the same values in the wordlist
- Pitchfork
    - Sniper but for multiple positions using different wordlists
    - iterates simultatiously
- Cluster Bomb
    - Same as pitchfork but iterates through wordlists one at a time

#### Decoder
Advanced decoding/encoding tool. Base64, hashes, hex etc

#### Comparer
Compare stuff, check for differences

#### Sequencer
Compare lots of strings in a sequenc to determine randomness

#### Extensions
Adds extensions to burp suite. Extensions can be written in Java, Ruby (JRuby) or Python (Jpython)