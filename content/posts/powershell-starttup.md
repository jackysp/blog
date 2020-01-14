---
title:  "如何在 Windows 开机后台启动一个 PowerShell 脚本"
date: 2020-01-14T08:56:00+08:00
---

* 创建一个脚本放在 `C:\Users\name\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\`
* 脚本里填

    ```shell
    Start-Process -FilePath "C:\Users\name\bin\gost-windows-amd64.exe" -ArgumentList "-L=", "-F=" -RedirectStandardOutput "C:\Users\name\bin\gost-windows-amd64.log" -RedirectStandardError "C:\Users\name\bin\gost-windows-amd64.err" -WindowStyle Hidden
    ```

注：`Start-Process` 好像会做一个 folk 类似的动作，默认会开启一个新的 PowerShell 窗口来执行，所以最后加上了 `-WindowStyle Hidden`，这里不能用 `-NoNewWindow`，因为这样只是让执行 `Start-Process` 不生成新窗口，老窗口不会退出。
注2：老窗口退出后，folk 出来的进程似乎成了孤儿被托管，所以可能会重新申请一下权限，比如，网络连接权限。