---
title:  "如何用 GitHub Action 自动发布 Blog"
date: 2020-12-16T16:11:00+08:00
draft: false 
---

在[这篇](/posts/travis-git-push)里用 travis 实现了 Blog 自动发布，不过，最近发现 travis 不自己 run 了（手动可以），没有仔细研究因为 GitHub Action 出来了，于是就想把所有依赖都放在 GitHub 上。

## Go Action

点击 repo 上的 Action，再 New Workflow 可以出现推荐 action，因为这个 Blog 用了 Go 代码，就显示 Go Action。

![goaction](/posts/images/20201216163209.png)

剩下的就是照着 travis 的写法来攒流程。

1. Check out Blog 的 repo
1. Check out 发布站点 repo
1. `make`
1. 提交发布站点修改

需要注意的是，发布站点需要写权限，所以，需要配置 token，跟 travis 一样。

1. 生成一个 token，只给 repo 权限
1. 到某个 repo 里，设置 secrets（把 token 填进去），这里其实应该在发布站点设置，但是，我在 Blog 里设置也可以用，还没研究原因

这里一共需要两个 action，一个是 GitHub 自己的，另一个是一个第三方的，叫 [《Push directory to another repository》](https://github.com/marketplace/actions/push-directory-to-another-repository)，可能还有别的更好用的，等以后有时间再研究。

最后，放上我的简单 GitHub Action CI 文件。

```yaml
name: CI

on:
  push:
    branches: [ master ]

jobs:
  build:
    name: Build
    runs-on: ubuntu-latest
    steps:

    - name: Set up Go 1.x
      uses: actions/setup-go@v2
      with:
        go-version: ^1.13

    - name: Check out code into the Go module directory
      uses: actions/checkout@v2

    - name: Get dependencies
      run: |
        go get -v -t -d ./...
        if [ -f Gopkg.toml ]; then
            curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
            dep ensure
        fi

    - name: Check out my other private repo
      uses: actions/checkout@v2
      with:
        repository: jackysp/jackysp.github.io
        token: ${{ secrets.UPDATE_BLOG }}
        path: public

    - name: Build
      run: make
    
    - name: Pushes to another repository
      id: public
      uses: cpina/github-action-push-to-another-repository@cp_instead_of_deleting
      env:
        API_TOKEN_GITHUB: ${{ secrets.UPDATE_BLOG }}
      with:
        source-directory: 'public'
        destination-github-username: 'jackysp'
        destination-repository-name: 'jackysp.github.io'
        user-email: your@email.com
        commit-message: See ORIGIN_COMMIT
```
