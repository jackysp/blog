---
title: "如何在 MacBook M1 上创建 GitHub Verified Commit"
date: 2022-02-12T11:54:00+08:00
---

## 背景

有一天手贱点开了 GitHub 的 Vigilant mode。

![test](/posts/images/2022-02-12-12.02.07.png)

于是，所有的 commit 就变成了下面这个样子。

![test](/posts/images/2022-02-12-12.11.01.png)

为了试着让他们怎么变成 Verified，于是找到了下面的方法。

## 方法

其实就是参照了这个[链接](https://zhuanlan.zhihu.com/p/76861431)。
但它是不够的，在 MacBook 上可能由于一些认证器的问题，会导致 commit 报错，于是，就找到了下面的[解决方法](https://stackoverflow.com/a/40066889)。

归纳下来就是，想要认证，需要填写密码，在 Mac 上提示填写密码的部分有问题，需要替换成 pinentry-mac，一般大家都用 homebrew 安装。

当然，这个解决方法还很贴心的提供了一个验证方法。

```shell
echo "test" | gpg --clearsign
```

## GPG 使用体验

1. 不是代替 ssh key 的，我验证成功后把 GitHub ssh key 删掉了，发现登录不了。其实，就只是验证 commit 的合法性的。
1. 在本机上，不管哪个 repo 里，只要输入一次密码就够了，就是 verified commit。倒是不影响日常使用。只是做这个的意义单纯的变成了打一个绿色标记。
1. 用 https 协议 + token 的方式感觉比这个还靠谱，不知道有没有 verified 标记。
