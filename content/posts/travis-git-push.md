---
title:  "如何在 travis ci 里执行 git push"
date: 2017-10-16T22:21:06+08:00
---

# 背景

Travis ci 一般用来自动化的跑下测试，而不需要将跑出来的内容更新回 repo 。本文介绍了怎么将 travis 的结果进行自动提交。

# 过程

基本过程参考了[这个gist](https://gist.github.com/Maumagnaguagno/84a9807ed71d233e5d3f)。

为了避免翻墙，将它的 `.travis.yml` 贴在下面。

```yml
language: ruby
rvm:
  - 2.0.0
env:
  global:
  - USER="username"
  - EMAIL="username@mail.com"
  - REPO="name of target repo"
  - FILES="README.md foo.txt bar.txt"
  - GH_REPO="github.com/${USER}/${REPO}.git"
  - secure: "put travis gem output here => http://docs.travis-ci.com/user/encryption-keys/"
script:
  - ruby test.rb
after_success:
  - MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
  - git clone git://${GH_REPO}
  - mv -f ${FILES} ${REPO}
  - cd ${REPO}
  - git remote
  - git config user.email ${EMAIL}
  - git config user.name ${USER}
  - git add ${FILES}
  - git commit -m "${MESSAGE}"
  - git push "https://${GH_TOKEN}@${GH_REPO}" master > /dev/null 2>&1
```

这里注意 MESSAGE 在 commit 的时候要加个引号，原 gist 没加。

原文的 README ：

```markdown
# Travis-CI tested push
Sometimes we have a private repository to hold both problems and solutions as a reference for the class projects.
The students can see only the problems in a public repository where they are able to clone/fork and develop their own solutions.
We do not want the solution files in the public repository and each bug found/feature added in the project requires a push for each repository.
It would be cool to work only with the reference repo and use tests to see if our modification is good enough for the public release.
This is possible with Travis-CI following simple steps:
- Create private and public repos
- Download Ruby
- Install the travis gem ``gem install travis``
- Generate a token in the Github website to allow others to play with your repos (copy the hash)
- Log into your git account
- Generate a secure token with the Travis gem (copy long hash)
- Fill the environment variables in the ```.travis.yml``` file (USER, EMAIL, REPO, FILES)
- Replace the value of **secure** with your long hash
- Replace **GH_TOKEN** with your Travis token name
- Push ```.travis.yml``` to private repo
- Go to Travis to unlock your private repo tests
- Push your files to the private repo to test

Travis now have a [deployment](https://docs.travis-ci.com/user/deployment/) feature, which may be better for certain scenarios.
```

简单翻译一下：

1. 创建 github 工程。原文看起来是创建了两个工程，一个工程用来更新另一个。
1. 安装 Ruby。一般同时安装了 gem 。
1. 通过 `gem install travis` 安装 travis 。
1. 给自己的 github 账号申请一个 token 。具体可以 Google 。需要注意的是 token 权限选择里，勾选 repo 相关的所有权限就可以了，其他无关的没必要选上。
1. 复制生成后的 token 。
1. 在本地机器上的 repo 根目录里（是不是必须根目录我也不清楚）`travis encrypt GH_TOKEN="上面复制的 token "`。这就创建了一个经过加密的 token ，这个 token 在使用的时候 `${GH_TOKEN}` 这样用。其实就是个环境变量。具体原理应该就是把 github 的 token 加密了一下。前面这个命令会输出一个字符串到屏幕，需要自己粘贴进 travis 配置文件，放在 secure: 后面。可以使用 `travis encrypt GH_TOKEN="上面复制的 token " --add` 来直接写进配置文件里。
1. 提交修改的配置文件。

没有完全按照上面的文字翻译。**上面这段内容更适用于下面这份我自己的配置文件：**

```yml
language: ruby
branches:
  only:
  - master
rvm:
- 2.4.1
exclude:
- vendor
sudo: false
env:
  global:
    - secure: rxKkyttLE1L4VsVIhhDUYGoLlER33ijKbdAAJPE8vNDSHwyANYnsP1GXK/rcwQqsL/KcJa55wEjVwEBzTMCqZM4UYNVIWqrJepVYo4rL1WhO+jT5sCqVR3qxK9KbgodcSXbmySJnJs0iLGMIQ2bo8yE91OxIC/GKkLCIwr9x4EGwFd5EcE5bOqmVqoSRk1q/1/5yA0aVF+Pohc5ATCZGw9+IyprU2Dx7qbA7F/T/4FQTOQZ4CLZAgyh/Gp1P+uxf1OK4IMCc/P6jVeTmbzQIbUcX0uG09pR7F0GnlV1ZOutMjY7SF8tQ7LNv2Wf8iWdiqehcwKNe/4TFHjs6rm3lEc6F1ELB5s4Z+QXjIM70haENSwM1FI8K5biL7tndAC1TujKESm0XadxORy5yOz7TfQZDTuMXvmmH3j+NFL3vTYPyMwwFca+IQBwD67a4PKD0PWBgEFD9Kn3rAlAzhV5OYdUuxZhx5zuQjKX5szUbL166fgoRnUwDp8dsOjLgOUqQa47IRqR3CTPzbf3zZIxGuX5x6mWySezCNprnXKCpyCegJBLoxQusA+EEYkvl4AOzhnmkhxFbEbHp+DYBjcSEEgpd06l67l3KzjMkpF02vr9CHNj8r7lAtZxwBVxYmczk289D5csOVR1SZKxQLwhx7k+CuEcYds685tLjIMmB0ZU=
    - USER="jackysp"
    - FULLNAME="Jack Yu"
    - EMAIL="jackysp@gmail.com"
    - REPO="jackysp.github.io"
    - GH_REPO="github.com/${USER}/${REPO}.git"
before_script:
  - git clone https://${GH_TOKEN}@${GH_REPO}
script: bundle exec jekyll b -d ${REPO}
after_success:
  - MESSAGE=$(git log --format=%B -n 1 $TRAVIS_COMMIT)
  - cd ${REPO}
  - git config user.email ${EMAIL}
  - git config user.name ${FULLNAME}
  - git add --all
  - git commit -m "${MESSAGE}"
  - git push --force origin master
```

这份文件是用来自动更新 jekyll 创建的 blog 的。分了两个工程，一个存源文件，一个存编译后的 html 文件。做这个的原因是，希望不用自己搭 jekyll 的环境也可以更新 blog 。这样即使是用在 github 网页上也可以更新 blog 了。
