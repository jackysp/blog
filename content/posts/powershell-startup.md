---
title: "How to Start a PowerShell Script in the Background at Windows Startup"  
slug: "how-to-start-a-powershell-script-in-the-background-at-windows-startup"
tags: ['powershell', 'windows']
date: 2020-01-14T08:56:00+08:00  
---

* Create a script and place it in

    ```powershell
    C:\Users\name\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup\`  
    ```

* Fill the script with:

    ```shell
    Start-Process -FilePath "C:\Users\name\bin\gost-windows-amd64.exe" -ArgumentList "-L=", "-F=" -RedirectStandardOutput "C:\Users\name\bin\gost-windows-amd64.log" -RedirectStandardError "C:\Users\name\bin\gost-windows-amd64.err" -WindowStyle Hidden
    ```

Note: `Start-Process` seems to perform a fork-like action, and by default, it opens a new PowerShell window to execute. That's why `-WindowStyle Hidden` is added at the end. You can't use `-NoNewWindow` here because it only prevents the creation of a new window for executing `Start-Process`, but the old window will not exit.  
Note 2: After the old window exits, the forked process seems to become an orphan and is managed elsewhere, so permissions, such as network connection permissions, might need to be requested again.
