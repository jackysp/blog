---
title: "Exploring Tailscale: Building Your Own Network Easily"
date: 2024-11-27T18:18:38+08:00
---

I recently started experimenting with **Tailscale**, a tool that has significantly simplified the way I manage my personal network across devices. In this blog post, I'll share how I discovered Tailscale, its core features, and my personal setup that leverages this powerful tool.

## Discovering Tailscale Through WebVM

My journey with Tailscale began when I came across [WebVM](https://github.com/leaningtech/webvm), an impressive project that allows you to run a virtual machine directly in your browser. Intrigued by the possibilities, I delved deeper and discovered that Tailscale could help me create a seamless, private network across all my devices.

## What is Tailscale?

Tailscale is a mesh VPN network built on top of **WireGuard**, specifically using the [WireGuard-go](https://github.com/WireGuard/wireguard-go) implementation. It allows you to create a secure, encrypted network between your devices, no matter where they are located.

### Key Features

- **Free Plan Available**: Tailscale offers a free plan that is sufficient for personal use, allowing up to 20 devices.
- **Ease of Use**: Setting up Tailscale is straightforward. With minimal configuration, you can have your own network up and running quickly.
- **Cross-Platform Support**: Tailscale works exceptionally well across the Apple ecosystem, including **iOS**, **tvOS**, and **macOS**.
- **Magic DNS Service**: It provides a built-in DNS service that makes it easy to address your devices by name.

## Performance on Different Platforms

While Tailscale shines on Apple devices, in my experience, it hasn't performed as well on Windows. I encountered some connectivity and stability issues on Windows machines, which may vary based on individual setups.

## My Tailscale Setup

Here's how I leveraged Tailscale to connect my devices and access my home network seamlessly.

### Running Tailscale on Apple TV

I installed Tailscale on my **Apple TV**, which stays online **24/7**. This makes it an excellent candidate for a consistently available node in my network.

- **Enabling Subnet Routing**: By enabling subnet routing on the Apple TV, I can access other devices on the same local network, such as my **NAS** and **router**, as if I were connected locally.
- **Setting Up an Exit Node**: I configured the Apple TV as an **exit node**, allowing me to route internet traffic through my home network. This is useful when I need to access geo-restricted content or ensure a secure connection.

### Connecting Other Devices

I also installed Tailscale on my **MacBook** and **iPhone**, which allows all my personal devices to communicate over the secure network, no matter where I am.

## Benefits I've Enjoyed

- **Secure Remote Access**: I can securely access my home network devices from anywhere.
- **Consistent Environment**: All my devices appear on the same network, simplifying file sharing and remote management.
- **No Need for Complex VPN Setups**: Tailscale eliminates the need for traditional VPN configurations, port forwarding, or dynamic DNS services.

## Conclusion

Tailscale has transformed the way I interact with my devices across different locations. Its ease of use and robust feature set make it an excellent choice for anyone looking to create a personal, secure network.

If you're interested in simplifying your network setup and want a hassle-free way to connect your devices, I highly recommend giving Tailscale a try.

**Links:**

- [Tailscale Official Website](https://tailscale.com/)
- [WebVM Project on GitHub](https://github.com/leaningtech/webvm)
- [WireGuard-go on GitHub](https://github.com/WireGuard/wireguard-go)

*Note: This post reflects my personal experiences with Tailscale. Performance may vary based on individual configurations and devices.*
