---
title: "Encounter with a Major Issue with Cloudflare Warp: A Life and Death Rescue for VPS"
date: 2024-05-15T20:31:00+08:00
draft: false
---

Today, I planned to use Warp to select an IP exit for my VPS, following the [Cloudflare official documentation](https://developers.cloudflare.com/warp-client/get-started/linux/). When executing the `warp-cli connect` step, the server immediately lost connection, and the problem persisted even after rebooting.

After researching, I found that this problem is not unique. For instance, in a [discussion on V2EX](https://www.v2ex.com/t/933725), many users encountered similar issues. The solution is to run `warp-cli set-mode proxy` before executing `warp-cli connect` to bypass the local address. Surprisingly, Cloudflare's official documentation does not mention this crucial step, undoubtedly increasing the complexity and risk of configuration.

In the process of exploring solutions, I found that some users suggested repairing by rebuilding the instance or using VNC connection. However, since I am using AWS Lightsail, VNC is not applicable. Ultimately, I decided to try the method mentioned in [this article](https://www.4os.org/2022/02/14/aws-lightsail-ssh-%E6%8C%82%E6%8E%89%E5%A6%82%E4%BD%95%E7%99%BB%E5%BD%95/): creating a snapshot backup of the current VPS, then creating a new instance from the snapshot, and loading a script to execute `warp-cli set-mode proxy` when the new instance starts.

After checking the existing instance, I found that no snapshot had been created. This discovery reminded me of the importance of regular backups. Without other options, I could only attempt a snapshot backup as guided by the aforementioned article. However, no matter what startup script command I tried, it failed to execute successfully. The execution result of AWS Lightsail's startup script is not visible, making problem-solving more difficult.

In near desperation, I found an old snapshot dated 2022 on the snapshot page. Although this snapshot was created using old technology, and many important updates might be lost after recovery, it was my last hope. After starting the snapshot recovery process, I unexpectedly discovered through the `history` command that this snapshot contained all the important updates. This discovery allowed the entire recovery process to be completed smoothly.

This experience re-emphasized the importance of backups. Careful backups from the past ultimately avoided severe data loss. Furthermore, AWS's static IP retention feature also played a crucial role. The new instance could immediately bind to the IP once the old instance released the static IP, achieving a seamless switch.

## Conclusion

1. **Backups are essential**: Regular backups are key to ensuring stable system operations.
2. **Operate with caution**: Before executing critical commands, thoroughly review and understand relevant documentation and user feedback to avoid potential risks.
3. **Trust your past self**: Meticulous work done in the past can often prove invaluable at critical moments.

I hope this experience can serve as a reference and help for others, preventing similar issues from occurring.
