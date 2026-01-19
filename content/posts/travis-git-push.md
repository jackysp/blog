---
title: "How to Execute Git Push in Travis CI"
slug: "how-to-execute-git-push-in-travis-ci"
date: 2017-10-16T22:21:06+08:00
---

## Background

Travis CI is generally used for automating tests without needing to update the repository with the test outputs. This article explains how to automatically commit the results from Travis CI.

## Process

The basic process references [this gist](https://gist.github.com/Maumagnaguagno/84a9807ed71d233e5d3f).

Below is the `.travis.yml` from the gist.

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

Note here that MESSAGE should be quoted when committing, which the original gist did not include.

Original README:

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

Travis now has a [deployment](https://docs.travis-ci.com/user/deployment/) feature, which may be better for certain scenarios.
```

A simple translation:

1. Create a GitHub project. The original seems to have created two projects, one for updating another.
2. Install Ruby. Usually, gem is installed alongside.
3. Install travis via `gem install travis`.
4. Apply for a token for your GitHub account. You can Google the details. When selecting token permissions, only tick all related to repo; others can be omitted.
5. Copy the generated token.
6. In the root directory of the local machine's repo (not sure if it must be the root) run `travis encrypt GH_TOKEN="copied token"`. This creates an encrypted token to use as `${GH_TOKEN}`, essentially an environment variable. The command output, a string on the screen, needs to be pasted into the travis config file after secure:. Use `travis encrypt GH_TOKEN="copied token" --add` to write directly into the config file.
7. Commit the modified configuration file.

This translation is not strictly literal. **The above content is more suited to the following personal configuration:**

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

This configuration is used for automatically updating a blog created with Jekyll. There are two projects, one for source files and another for compiled HTML files. The purpose of this setup is to allow updating the blog without having to set up a Jekyll environment, even allowing updates directly from the GitHub website.