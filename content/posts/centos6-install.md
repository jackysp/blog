---
title: "How to Install CentOS as a Virtualization Host"
slug: "how-to-install-centos-as-a-virtualization-host"
tags: ['centos', 'linux', 'virtualization']
date: 2014-06-05T22:21:06+08:00
draft: false
---

## Installation Process

Installed Version: CentOS 6.3

1. Using Win32DiskImager to create a USB flash drive image was unsuccessful; installing from an external USB optical drive was successful.
2. During the installation process, make sure to select the "Virtual Host" installation mode.
3. The rest can be set to default or slightly modified, such as choosing the time zone.
4. After installation, it will include the KVM suite and SSH.

## Installation Notes

* No internet connection is needed throughout the process, which is much better than Debian and Ubuntu.
* You're not forced to set up a non-root user.
* Before installation, be sure to check whether your CPU supports virtualization and enable the motherboard's virtualization setting. If the motherboard supports virtualization but doesn't have a virtualization option, you can still use virtualization as it's definitely enabled by default. There's a saying that Intel CPUs with a 'K' cannot perform virtualization. 'K' means Intel CPUs that can be overclocked. It seems that faster and newer CPUs are not necessarily better.
