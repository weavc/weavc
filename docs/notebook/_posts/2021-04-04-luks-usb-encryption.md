---
layout: md
title: Luks / Cryptsetup encrypted USB
description: ''
tags: ['linux', 'cryptography']
categories: ['linux', 'security']
sort_key: 1
---

{% include project-headers.html %}

#### Picking a cipher, mode, hash and key size
- Keysize, size does matter here...
- Whats available & best depends on the system and use case
- See `/proc/crypto` & `cryptsetup benchmark` for ciphers available 
- See `cryptsetup --help | tail -n 8` for defaults. Should be "Pretty good"
- Further Reading: 
  - [https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf](https://gitlab.com/cryptsetup/cryptsetup/-/wikis/LUKS-standard/on-disk-format.pdf)
  - [https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks](https://unix.stackexchange.com/questions/354787/list-available-methods-of-encryption-for-luks)
  - [https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size](https://superuser.com/questions/271902/system-encryption-luks-whats-the-strongest-and-most-secure-key-size)
- Useful extract:
> #### Valid cipher names
>```
>    aes Advanced Encryption Standard - FIPS PUB 197
>    twofish Twofish: A 128-Bit Block Cipher - https://www.schneier.com/paper-twofish-paper.html
>    serpent https://www.cl.cam.ac.uk/~rja14/serpent.html
>    cast5 RFC 2144
>    cast6 RFC 2612
>```
> #### Valid cipher modes
>```
>    ecb The cipher output is used directly.
>    cbc-plain The cipher is operated in CBC mode. 
>    cbc-essiv:{hash}
>    xts-plain64 plain64 is 64-bit version of plain initial vector
>```
> #### Valid hash specifications
>```
>    sha1 RFC 3174 - US Secure Hash Algorithm 1 (SHA1)
>    sha256 SHA variant according to FIPS 180-2
>    sha512 SHA variant according to FIPS 180-2
>    ripemd160 http://www.esat.kuleuven.ac.be/~bosselae/ripemd160.html
>```

I ended up going with `aes-xts-plain64`.

#### Find where usb is mounted
```bash
fdisk -h

...

Disk /dev/sdb: 29.45 GiB, 31609323520 bytes, 61736960 sectors
Disk model: Mass-Storage
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
```

#### Wipe the device
```bash
umount [/dev/sdb]
wipefs -a [/dev/sdb]
```

#### Encrpyt the device
```
cryptsetup -y --cipher [cipher] --key-size [keysize] luksFormat [/dev/sdb]
```
Will be prompted for the password here

#### Open
```
cryptsetup luksOpen [/dev/sdb] [some-volume-name]
```

#### Format
```
sudo mkfs.ext4 /dev/mapper/[some-volume-name] -L [some-volume-name]
```

#### Close
```
cryptsetup luksClose [volume-name]
```


