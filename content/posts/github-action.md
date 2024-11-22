---
title: "How to Automatically Publish a Blog Using GitHub Actions"
date: 2020-12-16T16:11:00+08:00
draft: false
---

In [this post](/posts/travis-git-push), I used Travis to enable automatic blog publishing. However, I recently discovered that Travis does not run automatically anymore (though it works manually). I haven’t looked into it closely because GitHub Actions have been introduced, so I decided to move all dependencies to GitHub.

## Go Action

Click on Actions on the repository page, and then New Workflow to see recommended actions. Since this blog uses Go code, it shows the Go Action.

![goaction](/posts/images/20201216163209.png)

The rest involves following Travis's approach to set up the workflow.

1. Check out the blog's repo
2. Check out the publishing site repo
3. `make`
4. Commit the changes to the publishing site

Note that write permissions are required for the publishing site, so you need to configure a token, similar to Travis.

1. Generate a token with only repo permissions
2. Go to a particular repo and set up secrets (enter the token). Ideally, this should be set up on the publishing site, but it works when set in the blog repo. I haven't explored why yet.

You will need two actions in total: one is GitHub's own [checkout](https://github.com/actions/checkout), and the other is a third-party action called [“Push directory to another repository”](https://github.com/marketplace/actions/push-directory-to-another-repository). There might be better options available, and I’ll explore them when I have more time.

Finally, here is my simple GitHub Action CI file:

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
