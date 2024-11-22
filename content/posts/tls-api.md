---
title: "How to Use the HTTP API in TiDB with TLS Enabled"  
date: 2023-05-22T21:45:00-07:00  
draft: true
---

## Background

Many NA (North America) customers have TLS enabled, which is different from the lab environment.

## Curl

Curl requires a specified CA certificate, otherwise it will report an error.

```bash
curl --cacert ca.crt https://127.0.0.1:10080/status
```

## Wget

Many containers do not have curl, so wget is used instead. Wget is better as it does not require a CA certificate.

```bash
wget --no-check-certificate http://127.0.0.1:10080/status
```
