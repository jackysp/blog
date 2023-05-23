---
title:  "如何在开启 TLS 的 TiDB 中使用 HTTP API"
date: 2023-05-22T21:45:00-07:00
draft: true
---

## 背景

遇到很多 NA 客户都开着 TLS，跟实验室环境不一样。

## Curl

curl 需要指定 CA 证书，否则会报错。

```bash
curl --cacert ca.crt https://127.0.0.1:10080/status
```

## Wget

好多 container 里没有 curl，就要用 wget，wget 更好，可以不需要 CA 证书。

```bash
wget --no-check-certificate http://127.0.0.1:10080/status
```
