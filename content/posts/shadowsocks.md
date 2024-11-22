---
title: "How to Deploy a Shadowsocks Server"
date: 2018-09-27T15:48:00+08:00
draft: false
---

There are multiple versions of the Shadowsocks server side implementation. The original version was written in Python, and later, enthusiasts implemented it in various programming languages of their liking.

Among all these implementations, I personally think the most reliable and stable one is the original Python version. The reason is simple - it has the most users. The Golang version is said to have the most features and also performs very well, making it quite powerful. This might be due to Golang’s inherent high performance and ease of implementation. There's also an implementation using libev, a pure C implementation, which also offers good performance and is very lightweight.

Additionally, updating the server is a necessary task for Shadowsocks users due to well-known reasons. The server should be updated frequently. If you’re using the Python implementation, you might be able to install updates via pip, although I haven’t confirmed this. The Golang version may require a Golang build environment, and then you can use `go get -u`. For updating libev, you can use apt on Debian-based systems, as apt includes shadowsocks-libev. I haven’t checked if it is available in the Red Hat-based yum repositories.

After this introduction, let's go over the deployment steps, which are quite straightforward:

1. Deploy a Debian 9 or Ubuntu 17 VPS. Mainstream providers like Vultr should have these options available. Assume we are using Debian 9 here.
2. Run `apt install shadowsocks-libev` to install.
3. Edit the configuration file using `vim /etc/shadowsocks-libev/config.json`. It's best to set the Server IP to 0.0.0.0 to avoid IP issues similar to those on AWS Lightsail.
    1. For AWS Lightsail, you need to bind a static IP and open firewall ports. Specific steps can be found on Google.
4. Restart the service using `systemctl restart shadowsocks-libev` to apply the changes.
5. Enable TCP BBR. Specific instructions can be found on Google.
