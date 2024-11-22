---
title: "How to Deploy an HTTPS Proxy Service"
date: 2020-01-12T19:43:00+08:00
draft: false
---

## Preface

One day, I came across an article by Chen Hao on Twitter. Having benefited from several of his blog posts, I instinctively felt it was reliable, so I read it and decided to write this practical guide.

## Why Use an HTTPS Proxy

In the [guide](https://haoel.github.io/), it’s clearly explained why, plus my own experiences of several shadowsocks being banned, I felt it was necessary to switch to a more secure proxy method.

## How to Deploy an HTTPS Proxy

### gost

[gost](https://github.com/ginuerzh/gost) is the tool most recommended in the [guide](https://haoel.github.io/). At first, I misunderstood it as a method similar to kcptun, still relying on shadowsocks. In fact, gost implements multiple proxy types, meaning you don’t need other proxies if you have it. I never liked the method of continuously wrapping to accelerate/obfuscate shadowsocks, always feeling that longer pathways bring more problems.

### Steps

- Directly download the latest release from the gost repo. Although I have a Golang environment both locally and on the VPS, downloading directly is the easiest. I downloaded version 2.9.0 here.
- Following certbot on a bare VPS doesn't work... it requires:
  1. Starting an nginx server, as referenced in [this guide](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-9). Of course, this requires having a domain name pointing an A record to the VPS.
  2. Verifying access through the domain.
  3. Stopping nginx.
  4. Using certbot's --standalone mode, which will generate the certificates upon success.
- Here, I didn't use Docker for deployment but used systemd instead, directly creating a systemd unit similar to kcptun. The difference is, because the certificate needs updating, the unit requires a reload method. [This tutorial](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html) teaches a lot about using systemd, and the author's article quality is also high, highly recommended for subscription.
  
  1. Create a `/lib/systemd/system/gost.service` file with the following content, replacing the domain with your own:

    ```text
    [Unit]
    Description=gost service
    After=network.target
    StartLimitIntervalSec=0

    [Service]
    Type=simple
    Restart=always
    RestartSec=1
    User=root
    PIDFile=/home/admin/gost.pid
    ExecStart=/home/admin/bin/gost -L "http2://xxx:yyy@0.0.0.0:443?cert=/etc/letsencrypt/live/example.com/fullchain.pem&key=/etc/letsencrypt/live/example.com/privkey.pem&probe_resist=code:404"
    ExecReload=/bin/kill -HUP $MAINPID

    [Install]
    WantedBy=multi-user.target
    ```

    `ExecStart` is a simplified version of the Docker method in the [guide](https://haoel.github.io/). `ExecReload` just kills the process.
    
  2. Test whether it’s successful using `systemctl start|status|restart|enable gost`.

  3. Configure crontab to update the certificate. I didn't use systemd because I'm not familiar with it.

    ```text
    0 0 1 * * /usr/bin/certbot renew --force-renewal
    5 0 1 * * systemctl restart gost
    ```

- After completing the above, nginx can be directly stopped and disabled.

- Configure the client. This is simple; just refer to the [guide](https://haoel.github.io/). The principle is straightforward because gost implements the shadowsocks protocol using the shadowsocks Golang version. Therefore, the following command starts a local shadowsocks server, and you configure your client to add a local server configuration that matches the password.

    ```text
    .\bin\gost-windows-amd64.exe -L=ss://aes-128-cfb:passcode@:1984 -F=https://xxx:yyy@example.com:443
    ```

PS: I still don't know how to configure a global HTTPS proxy on Android without root, or how to set it up on iOS without a U.S. account. Also, I'm unsure how to elegantly configure startup scripts on Windows 10. These are issues to explore further...

## Continuation

Regarding the mobile problem mentioned above, I found that HTTPS proxy client support is generally poor. Gost itself seems to have problems, possibly due to my usage. In short, if not using a local gost to connect remotely, authentication errors occur.

During the holiday break, I tinkered a bit more. First, I deployed a gost HTTP proxy on my home NAS using the simplest nohup + ctrl-D method to maintain it. It's compiled with GOARCH=arm64. After a trial run for a day, Android's weak built-in HTTP proxy worked well, but globally routing through it wasn't great. Hence, I switched from HTTP to using SS to connect to HTTPS remotely. I essentially moved the local service on Windows to my NAS. Additionally, through simple double-port forwarding from NAS -> internal router -> optical modem router, I could also use the NAS as an SS server via the public IP.

The remaining issue is the DDNS. After researching, it seems Cloudflare's API is a more reliable option. Seeing an official flarectl, I compiled it to the NAS and wrote a small script, revisiting the various (pitfalls) wonders of bash, especially remembering special writing for string comparisons such as `[ $a != $b ]` to `[ $a != $b* ]` to handle trailing "\r" "\n" characters. However, detaching the name server still takes some time. The final effect is to be tested.

Additionally, on the NAS, I currently use curl to fetch my public IP from a third-party. I have a hunch that this method might not work someday or might cause issues.
