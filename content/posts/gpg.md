---
title: "How to Create GitHub Verified Commits on a MacBook M1"
date: 2022-02-12T11:54:00+08:00
---

## Background

One day, I impulsively turned on GitHub's Vigilant mode.

![test](/posts/images/2022-02-12-12.02.07.png)

As a result, all my commits started looking like this.

![test](/posts/images/2022-02-12-12.11.01.png)

To figure out how to make them Verified, I found the following method.

## Method

I actually referred to this [link](https://zhuanlan.zhihu.com/p/76861431). However, it wasn't quite enough, as there might be authentication-related issues on MacBooks that lead to commit errors. So, I found this [solution](https://stackoverflow.com/a/40066889).

In summary, to verify, you need to enter a password. The issue on a Mac is the prompt for entering the password, which needs to be replaced with pinentry-mac, which most people install via homebrew.

Moreover, this solution thoughtfully provides a way to verify:

```shell
echo "test" | gpg --clearsign
```

## GPG Experience

1. It doesn't replace the ssh key. After successfully setting it up, I deleted my GitHub ssh key and discovered that I couldn't log in. Actually, it only verifies the legitimacy of commits.
2. On the local machine, in any repo, you only need to enter the password once, and that makes it a verified commit. It doesn't affect daily use; it just adds a green check mark for verification.
3. Using the https protocol + token seems more reliable than this method, but I'm not sure if it provides a verified mark.