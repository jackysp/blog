---
title: "How to Configure CentOS KVM Network Bridging Mode"
date: 2014-06-05T22:21:06+08:00
---

## What Is Bridging

Bridging highly simulates a network card, making the router believe that the virtual machine's network card truly exists. Personally, I feel it's similar to resistors connected in parallel, whereas NAT (another common virtual machine network connection method) is more like parasitizing on the host's network card.

## Why Use Bridging

It allows you to treat the virtual machine as a completely independent machine, enabling mutual access with the external network (which is not possible with NAT).

## How to Configure Bridging

In CentOS 6, refer to the command-line method in [this article](http://www.techotopia.com/index.php/Creating_a_CentOS_6_KVM_Networked_Bridge_Interface).

We don't use the GUI method because:

* We're unsure which options to fill in on the last screen.
* We don't know how to reset if we make a wrong selection.

Command-line steps:

1. **Check if `bridge-utils` is installed:**

   ```bash
   rpm -q bridge-utils
   ```

   Usually, it's already installed. If not, install it:

   ```bash
   su -
   yum install bridge-utils
   ```

2. **Verify your network interfaces:**

   Run `ifconfig` to ensure you have at least three network interfaces:

   ```text
   eth0      Link encap:Ethernet  HWaddr 00:18:E7:16:DA:65
             inet addr:192.168.0.117  Bcast:192.168.0.255  Mask:255.255.255.0
             inet6 addr: fe80::218:e7ff:fe16:da65/64 Scope:Link
             UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
             RX packets:556 errors:0 dropped:0 overruns:0 frame:0
             TX packets:414 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:1000
             RX bytes:222834 (217.6 KiB)  TX bytes:48430 (47.2 KiB)
             Interrupt:16 Base address:0x4f00

   lo        Link encap:Local Loopback
             inet addr:127.0.0.1  Mask:255.0.0.0
             inet6 addr: ::1/128 Scope:Host
             UP LOOPBACK RUNNING  MTU:16436  Metric:1
             RX packets:8 errors:0 dropped:0 overruns:0 frame:0
             TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:0
             RX bytes:480 (480.0 b)  TX bytes:480 (480.0 b)

   virbr0    Link encap:Ethernet  HWaddr 52:54:00:2A:C1:7E
             inet addr:192.168.122.1  Bcast:192.168.122.255  Mask:255.255.255.0
             UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
             RX packets:0 errors:0 dropped:0 overruns:0 frame:0
             TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:0
             RX bytes:0 (0.0 b)  TX bytes:2793 (2.7 KiB)
   ```

3. **Navigate to the network scripts directory:**

   ```bash
   su –
   cd /etc/sysconfig/network-scripts
   ```

4. **Bring down the `eth0` interface:**

   ```bash
   ifdown eth0
   ```

   *This step is crucial and must be performed locally.* When I first configured this, I didn't shut down the network (since I was working remotely). I didn't realize that updating the `ifcfg-eth0` configuration without restarting the network would immediately apply changes, resulting in loss of network connectivity.

5. **Edit `ifcfg-eth0`:**

   In the `ifcfg-eth0` file, include:

   ```text
   DEVICE=eth0
   ONBOOT=yes
   BRIDGE=br0
   ```

   Keep only these three lines in the file. There's no need to configure an IP address here. Bridging seems to replace the original network card with the bridge, so you can delegate the configuration to the bridge.

6. **Create a new file `ifcfg-br0`:**

   ```text
   DEVICE=br0
   ONBOOT=yes
   TYPE=Bridge
   BOOTPROTO=static
   IPADDR=xxx.xxx.xxx.xxx   # Use the IP you originally had in ifcfg-eth0
   GATEWAY=xxx.xxx.xxx.xxx  # Your gateway address
   NETMASK=255.255.255.0    # Your netmask
   DNS1=xxx.xxx.xxx.xxx     # Your primary DNS server
   DNS2=xxx.xxx.xxx.xxx     # Your secondary DNS server (if any)
   STP=on
   DELAY=0
   ```

   *Note:* Replace `xxx.xxx.xxx.xxx` with your actual network settings.

7. **Bring up the interfaces:**

   ```bash
   ifup br0
   ifup eth0
   ```

8. **Verify the bridge interface:**

   Check `ifconfig` to ensure that `br0` is now present.

9. **Update firewall rules:**

   Edit `/etc/sysconfig/iptables` and add:

   ```text
   -A INPUT -i br0 -j ACCEPT
   ```

   *(This is a general example; you may need to adjust it based on your specific firewall configuration.)*

10. **Restart the firewall:**

    ```bash
    service iptables restart
    ```

11. **Configure bridging in `virt-manager`:**

    When creating a new virtual machine using `virt-manager`, you can now select `br0` for the network interface. Without this bridge, the bridging option would not be available.

**Note:** When configuring the IP inside the virtual machine, be sure to specify the `GATEWAY`. Otherwise, the virtual machine will only be able to access the internal network and not the external network. At this point, the virtual machine won't automatically discover the gateway.
