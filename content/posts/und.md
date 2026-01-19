---
title: "How to Dynamically Update DNS Records for Namesilo"
slug: "how-to-dynamically-update-dns-records-for-namesilo"
date: 2020-02-01T12:27:00+08:00
draft: false
---

## Dynamically Updating DNS Records

The purpose of dynamic updates is pretty simple. As a long-term user of China Unicom's broadband, although Unicom provides a public address, it is essentially a dynamic address, not a fixed one. If you want to access your home devices using an IP address from outside, you need to use dynamic DNS (DDNS). 

Many routers come with built-in DDNS functionality, but they mostly wrap the interfaces of the commonly used service providers. These providers generally have a few characteristics: 1. Blocked by the Great Firewall; 2. Not cheap; 3. Domestic providers may have security issues; 4. The company might have gone out of business. Rather than relying on these unreliable services, it's better to write your own script for updating.

Thus, the scripting approach comes into play. Initially, I planned to use Cloudflare, as it is the recommended way. Later, I discovered that my domain provider Namesilo offers an API to update DNS. However, it returns data in XML format, and I wasn't sure how to parse this with shell scripts.

Then, I thought of using Go. Since this DDNS client would likely be deployed on a router-like device, languages like Python or Java require a runtime environment, and C might need some dynamic libraries to run, which I wasn't sure how to handle. The fact that Go doesn't require dynamic libraries was a significant advantage. So, I handwrote a tool called [und](https://github.com/jackysp/und).

1. First, create a DNS record in Namesilo.
2. Obtain the binary of `und` suitable for your platform. I only provide binaries for arm64|linux and amd64|three mainstream OS in this case. For other platforms, you'll need to compile it yourself. You can refer to the Makefile.
3. Generate an API key from Namesilo, then start `und` according to its usage documentation. You might need to run it in the background, so use `nohup`.

## GitHub Features Experience

### GitHub Actions

It feels like a replacement for chaotic third-party CI services. I directly chose the Go option for `und`. By default, it simply runs `go build -v .` in Ubuntu.

### Release

I used this feature when releasing TiDB before, but didn't remember to upload/automatically generate binaries. Since TiDB is not something that can run completely with just one component, releasing a single binary doesn't make much sense. 

This time, the experience led me to believe:

1. When releasing, tagging is best done directly using the release feature.
2. After the release, since you can edit it, it's a good time to `make` each binary and upload them. Based on the Makefile setup, you can generate a version. This is quite an important feature.

These two steps are quite convenient.