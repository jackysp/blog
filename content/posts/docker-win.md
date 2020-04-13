---
title:  "如何在 Windows 中使用 Docker"
date: 2020-04-13T10:34:00+08:00
---

## 背景

因为要复现一个 bug，所以，不得已在 Windows 上安装 Docker。

## 过程

1. 以 Windows 10 为例，首先，如果是 Home Basic 版本，要花钱升级到 pro 版本，因为需要开启 Hyper-V 和 Container 两个功能，大概 800 RMB。
1. 一切按默认安装，不要切换成 Windows 的 Container，因为，大部分 image 还是在 Linux 下的。如果切换了，可以启动后切回来。
1. 使用中，如果遇到共享文件夹的权限问题，按照 https://github.com/docker/for-win/issues/3174 来解决一下。当然，很可能解决不了，会报告共享失败。然后呢，去 setting 里面的 troubleshoot，reset to factory defaults 吧。重置之后，先把共享文件夹勾好。
1. 使用中，只要遇到错误，多试几次吧。可能能搞定的，不行就重置。

## 感受

最早在 linux 下用没什么问题，docker 当时本身也很简单。后来在 mac 下用就完全变了，也有界面了，也有各种颜色了，也 full of bugs 了。一上来就是 bug。很早之前记得 docker 不支持 windows，加上上次 mac 的各种 bug，本来没有太大期待。结果还是有些让人大跌眼睛的。
总的讲就两句，1. 更易用了；2. 更多 bug 了。基本上就不要指望啥，随时做好重置的准备吧。好在，重置也给了一个快捷方式，是个易用性不错的玩具。3. 慢得出奇。
现在，完全不看好 docker、k8s 之类。完~