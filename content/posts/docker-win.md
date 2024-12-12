---
title: "How to Use Docker on Windows"
date: 2020-04-13T10:34:00+08:00
---

## Background

I had to install Docker on Windows to reproduce a bug.

## Process

1. Using Windows 10 as an example, if you have the Home Basic version, you'll need to pay to upgrade to the Pro version because you need to enable Hyper-V and Container features, which costs about 800 RMB.
2. Install everything with the default settings, and do not switch to Windows Containers, since most images are still under Linux. If you do switch, you can restore it after starting up.
3. If you encounter permission issues with shared folders, follow the instructions at [link](https://github.com/docker/for-win/issues/3174). However, this might not solve the problem, and you might encounter a sharing failure. In that case, go to the settings, troubleshoot, and reset to factory defaults. After resetting, ensure the shared folders are selected.
4. When you encounter errors during use, just try a few more times. It might work; if not, reset it.

## Impressions

Initially, there were no issues using Docker on Linux; Docker itself was simple back then. Later, using it on Mac brought changes, including a user interface, various colors, and numerous bugs. Right from the start, I encountered bugs. Docker did not support Windows a long time ago, and given the various bugs on Mac, I didn't have high expectations. The results were still quite surprising. In summary, here are a few points:

1. It's easier to use.
2. There are more bugs. Do not expect much, and be prepared to reset at any time. Fortunately, resetting offers a shortcut, making it a pretty usable tool.
3. It's incredibly slow.

At this point, I have no optimism for Docker, Kubernetes, or similar technologies. Done~
