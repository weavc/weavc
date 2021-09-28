---
layout: md
title: M3 Enigma Emulator
repo: weavc/enigma
description: Python based M3 Enigma emulator with a flask frontend
tags: ['python', 'flask', 'cryptography', 'enigma', 'docker']
sort_key: 1
pinned: true
---

{% include project-headers.html %}

![Python tests](https://github.com/weavc/enigma/workflows/Python%20tests/badge.svg)
[![Docker](https://img.shields.io/badge/docker-releases-blue?logo=docker)](https://github.com/weavc/enigma/packages?ecosystem=docker)

Python based M3 Enigma emulator with a flask based web interface (and cli). I originally created the CLI based emulator for a project in university, has since been updated, tidied up, a flask web interface added and tests have been done.

### Enigma

The Enigma machine was used during WW2 by the Germans to encrypt and decrypt their day to day communications, this way it couldn't be intercepted and read by the enemy. Each day they would change the settings that were used to encrypt their messages making it extraordinarily difficult to crack, with over 17,000 combinations from the 3 rotors alone. With the ring settings, plugboard with 10 connections, reflector and multiple rotors to choose from in different orders, that 17,000 combinations quickly adds up to over 150 trillion combinations of settings that could be used.

A weakness was found in the encryption system however, allowing us to decipher german messages, this is widely thought to have knocked off 2 years of the war and saved numerous lives in the process.

There are a number of revisions of Enigma, this repository only implements the `M3` version currently. This was probably the most common version used during the war, but was replaced by the `M4` version in some areas of the german military.

### Random information

- Encryption and decryption are handled the same way, messages must be decrypted with the same settings that were used to encrypt it
- Each different Rotor uses the same set of characters, but mixed up differently. They also have different turnover points (The point at which the next rotor turns)
- keypress -> plugboard -> static rotor -> right rotor -> middle rotor -> left rotor -> reflector -> left rotor -> middle rotor -> right rotor -> static rotor -> plugboard -> light
- Each keypress turns the right most rotor +1, if it reaches its turnover point this causes the middle rotor to move +1 as well. And if that reaches its turnover point the left rotor will move +1. This happens when the key is pressed, before the machine starts calculate the output
- Ring settings change the output of the rotor, offset by the number associated with the character. i.e. a=0, z=25. This offset does not affect the turnover points and should be applied before the inputting the message.

### Useful Resources

- https://en.wikipedia.org/wiki/Enigma_rotor_details
- http://summersidemakerspace.ca/projects/enigma-machine/
- https://en.wikipedia.org/wiki/Enigma_machine

<!--- 
### Embeded demo 

[https://enigma.weav.ovh](https://enigma.weav.ovh)

{% include enigma-iframe.html %}
-->

