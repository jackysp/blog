---
title:  "如何让一台 Linux 笔记本电脑合上盖子后不进入休眠"
date: 2020-03-31T20:31:00+08:00
---

本来以为是一个很简单的设置，就随便 Google 了一下，果然有清一色的解法，就是修改 `/etc/systemd/logind.conf`，把 `HandleLidSwitch` 改成 `ignore` 或者 `lock`，然后，重启 `logind` 或者 `reboot`。
试了下，发现在 Thinkpad X230 下根本不行，于是又改了上述文件的其他一些选项，发现都不行，而且 `Ubuntu` 竟然报错了。。。

于是，重装了更喜欢的 `Debian`。重试，发现还是不行。最后，找到了一个最暴力的解决办法。

```shell
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

直接把这几个 unit 指向了 /dev/null。。。

想恢复的话就，

```shell
systemctl unmask sleep.target suspend.target hibernate.target hybrid-sleep.target
```

简单有效。
