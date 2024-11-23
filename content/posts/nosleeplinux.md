---
title: "How to Prevent a Linux Laptop from Entering Sleep Mode When the Lid is Closed"
date: 2020-03-31T20:31:00+08:00
---

Initially, I thought it would be a simple setting adjustment, so I casually Googled it. Sure enough, there was a unanimous solution: modify `/etc/systemd/logind.conf`, change `HandleLidSwitch` to `ignore` or `lock`, and then restart `logind` or reboot.

I tried this, but it didn't work at all on my Thinkpad X230. I then tried changing some other options in the aforementioned file, but none worked, and surprisingly, `Ubuntu` even reported errors.

So, I reinstalled the more preferred `Debian`. Tried again, and it still didn't work. Finally, I found a more brutal method.

```shell
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

This directly points these units to /dev/null...

To revert, simply use:

```shell
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

It's simple and effective.

**Update:**

If you only mask them, the CPU usage of systemd-logind will be very high because it continuously attempts to sleep. Therefore, you also need to change `HandleLidSwitch` and others to `ignore`. As follows:

```text
HandleSuspendKey=ignore
HandleHibernateKey=ignore
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
```

Then, execute `systemctl restart systemd-logind`. For more details, refer to this: [SystemD-LoginD High CPU Usage](https://tothecloud.dev/systemd-logind-high-cpu-usage/).
