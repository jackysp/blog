---
title: "Introduction to WebVM"
date: 2025-01-13T19:54:00+08:00
---
## What is WebVM?

[WebVM](https://github.com/leaningtech/webvm) is a virtual machine (VM) that executes entirely within a web browser. It's an innovative project that brings the power of a Linux environment straight to your browser, eliminating the need for traditional virtual machine setups. WebVM operates within a sandboxed environment, ensuring secure execution of applications without affecting the host system.

## Understanding WebVM

The source repository provides a frontend for the WebVM demo. By forking the repository and following the instructions outlined in the GitHub Actions, you can build an image using the Dockerfile located at:

- [Debian Large Dockerfile](https://github.com/leaningtech/webvm/blob/main/dockerfiles/debian_large)

This image can then be hosted on GitHub Pages, as demonstrated in my [demo](https://blog.minifish.org/webvm/).

![](/posts/images/20250113_195726_image.png)

WebVM's primary functionality is to stream resources to the browser, minimizing client-side resource consumption. It enables the execution of various applications that are typically restricted to virtual machines, all within a browser. Additionally, WebVM allows for the embedding of these applications through custom front-ends.

## Default Image and Capabilities

The default WebVM image is **Debian-mini**, which may have limited capabilities. To enhance its functionality, I have opted for the **Debian-large** image, which has been extended to a 2GB disk capacity. This provides a more robust environment with additional tools and packages.

## Usage and Benefits

WebVM offers a range of applications and capabilities:

1. **Custom Image Creation:** Create custom images tailored to your specific requirements, allowing for a personalized virtual environment.
2. **Web-Based Linux Terminal:** Access a web-based Linux terminal to execute Linux commands directly within the browser. This includes:

   - **SSH/SCP File Transfers:** Securely transfer files using SSH and SCP protocols.
   - **HTTP Server Initiation:** Start an HTTP server using `python3 -m http.server`.
3. **Sandboxed Security:** Operates within a sandbox environment, ensuring secure execution of applications without affecting the host system.
4. **Serverless Architecture:** Embraces a serverless architecture by executing entirely on the client side. Running a Linux server within a browser presents a unique and innovative approach to virtualization.

## Alternative Options

Yes, there are alternative options. [JSLinux](https://bellard.org/jslinux/) is a preferred and faster option. However, it does not allow modifications to the image, which can be a limitation if you require a customized environment.

## Additional Tips

- **Internet Connectivity via Tailscale:**

  WebVM can connect to the internet via [Tailscale](https://tailscale.com/). It utilizes the first available node as an exit node. If you execute:

  ```bash
  curl https://ifconfig.me
  ```

  You will obtain your current node's IP address.
- **DNS Functionality:**

  The DNS functionality of Tailscale is currently experiencing issues. It's recommended to use IP addresses to connect to other nodes within your Tailscale network instead of domain names.
- **Default Credentials:**

  You can obtain the default `user:password` and `root:password` credentials by checking the Dockerfile:

  - [Default Credentials in Dockerfile](https://github.com/leaningtech/webvm/blob/main/dockerfiles/debian_large#L15-L18)

## Conclusion

WebVM is a powerful tool that brings the versatility of a Linux environment to your browser. Whether you're looking to experiment with Linux commands, develop applications, or require a portable and sandboxed environment, WebVM offers a serverless and secure solution. Its ability to create custom images and operate entirely on the client side sets it apart from other web-based virtual machines.

Feel free to explore WebVM and customize it to suit your needs. Happy coding!
