---
title: "{{ replace .Name "-" " " | title }}"
slug: "{{ path.BaseName .File.Dir }}"
date: {{ .Date }}
draft: false
tags: []
---
