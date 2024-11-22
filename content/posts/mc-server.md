---
title: "How to Set Up a Minecraft Bedrock Server Using Multipass"
date: 2022-05-02T19:05:00+08:00
draft: false
---

## Background

Recently, both of my kids have become interested in Minecraft, and some of their peers are also playing it. We previously bought the Switch version, but its online capabilities are quite poor, and the device performance is subpar, resulting in a less-than-ideal experience. Thus, I began considering the idea of setting up our own server. Of course, you can play in multiplayer with friends, but the game ends as soon as the host goes offline, which is not as good as having a server that is always online.

For version selection, there is the NetEase version, the official Java version, and the Bedrock version. Based on my previous understanding, the NetEase version has all sorts of anti-addiction regulations, so that's a no-go. The Java version server setup seems to rely on third-party launchers, resembling piracy to some extent. Therefore, I decided on the Bedrock version. Another reason for choosing the Bedrock version is its origins as the mobile version of Minecraft, and Microsoft later [expanded support to more platforms](https://minecraft.fandom.com/zh/wiki/%E5%9F%BA%E5%B2%A9%E7%89%88?variant=zh), making it the most versatile. Additionally, its core is written in C++, which should offer better performance and resource efficiency.

## Downloading the Server Software

I downloaded the [Ubuntu version](https://www.minecraft.net/en-us/download/server/bedrock). While I also downloaded the Windows version and managed to run it, I’m not experienced in managing Windows Server, and the Windows version has some quirks. I won’t delve into those here.

## Local Network Server

Initially, I intended to use an old Thinkpad, but couldn't find it, and ended up using an old Macbook. After updating everything, I found that the old Macbook was still quite robust, outperforming the Thinkpad. So, I set up a virtual machine. I discovered that Ubuntu Server no longer supports direct ISO downloads, requiring Multipass to launch instead.

What is Multipass?

Developed by the Ubuntu team, it is a lightweight virtualization platform. Multipass consists of `multipass` and `multipassd`. The former provides both GUI and CLI, while the latter requires root permissions and runs in the background. It can be downloaded directly or installed via brew cask.

Multipass seems to only install Ubuntu Server, with some customization, such as automatically creating a user named "ubuntu" and key pairing. Once installed, you get a 1C 1GB virtual machine called "primary" that automatically mounts the user’s home directory.

`multipassd` is more of a pluggable virtual hypervisor supporting hyperkit and qemu by default, with hyperkit intended for Intel macOS and qemu for M1.

`multipassd` can also use Virtualbox as a backend hypervisor, which is more recommended because it offers bridging capabilities, whereas relying solely on port mapping would be cumbersome. It's not that qemu doesn't support bridging, but there’s an easy-to-follow [Virtualbox bridging tutorial](https://multipass.run/docs/set-up-the-driver) on Multipass’s official documentation.

I set up Virtualbox first. I must say, Oracle is generous here as it's still free to use. Then, I followed the steps from the link above. It's essential to reboot the machine after running the first step `sudo multipass set local.driver=virtualbox`, as the variable might not take effect immediately. Otherwise, the primary created will still use the old backend. Since there's already a default virtual machine, I didn't want to create another one to avoid extra resource usage. Additionally, note a few things:

1. For modifying primary configuration, I didn’t find a way to do it using Multipass, so I used vbox’s command `sudo VBoxManage controlvm "primary" --cpus 2 --memory 4096` (where memory is in MB).
2. The primary mount point in Multipass can automatically unmount in some situations, resulting in errors. Therefore, Minecraft data shouldn’t be stored in the mount point permanently to avoid core dumps.

After extracting the server files, just start it in tmux/screen.

Lastly, I used [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12) from the App Store to ensure that the laptop continues working when closed by disabling the default sleep setting after the screen is closed. You’ll see some warnings when doing this, but just be aware of them.

**Update:**

For systemd startup, you can refer to [this gist](https://gist.github.com/gatopeich/36ed7fab3850367bbcd8e6f40becd4e5). The server's console has some commands, like "stop", that perform graceful shutdowns, so it's necessary to rely on a screen session to create it. Additionally, the server startup has some environmental dependencies, so it’s best to write a small script for starting it, like:

```bash
#!/bin/bash

cd /home/user/bedrock-server
LD_LIBRARY_PATH=. ./bedrock_server
```

Using absolute paths can lead to core dumps.

## Public Network Server

For public network servers, the choices are to map the internal network to the public network or purchase a cloud server. Due to security concerns, I opted to buy a cloud server. Although the official site mentioned Ubuntu support, I found that Debian servers also run without issues. The only thing to note is that the Bedrock version uses UDP, and China Unicom’s 5G network disables UDP, so without WiFi, you cannot connect.

## Server Monitoring

To monitor the server’s status, monitoring is necessary, especially for cloud servers, as provider information might be insufficient. I used [Grafana Cloud](https://grafana.com/products/cloud/).

Using the free version is fine, just follow the guide to select a Linux server integration, then run the Grafana Agent installation and verification on the server to be monitored. Note to change the hostname in the Grafana Agent configuration file to differentiate between different servers, which acts as a label.

I understand that Grafana Agent is a lightweight node exporter with some Prometheus functionalities, but it can also remote write, so there's no need to worry about the disk filling up.

