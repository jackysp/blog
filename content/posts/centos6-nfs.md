---
title: "How to Configure CentOS 6 NFS Service"
slug: "how-to-configure-centos-6-nfs-service"
date: 2014-06-05T22:21:06+08:00
---

## Server Side

1. **Disable SeLinux**  
   Edit the configuration file:

   ```bash
   vi /etc/selinux/config
   ```

   Modify as follows:

   ```text
   #SELINUX=enforcing    # Comment out
   #SELINUXTYPE=targeted # Comment out
   SELINUX=disabled      # Add this line
   ```

   Then reboot the system:

   ```bash
   reboot  # Restart the system
   ```

2. **Create a Directory**  
   Using the root user, create a directory named `/nfs`. Note: It's best to check which partition has the most space by running `df`, as the root (`/`) partition may not have the most space. In some automatic partitioning setups, the `/home` partition may have the most space.

3. **Install NFS Utilities and RPC Bind**  

   ```bash
   yum -y install nfs-utils rpcbind
   ```

4. **Enable Services at Boot**  

   ```bash
   chkconfig nfs on
   chkconfig rpcbind on
   chkconfig nfslock on
   ```

5. **Configure Exports**  
   Edit the NFS exports file:

   ```bash
   vi /etc/exports
   ```

   Add the following line:

   ```text
   /home/nfs 192.168.1.0/24(rw,sync,no_all_squash)
   ```

6. **Start NFS Services**  

   ```bash
   service rpcbind start
   service nfs start
   service nfslock start
   exportfs -a
   ```

7. **Configure NFS Ports**  
   Edit the NFS configuration file:

   ```bash
   vi /etc/sysconfig/nfs
   ```

   Uncomment the following lines:

   ```text
   LOCKD_TCPPORT=32803
   LOCKD_UDPPORT=32769
   MOUNTD_PORT=892
   ```

8. **Restart NFS Services**  

   ```bash
   service rpcbind restart
   service nfs restart
   service nfslock restart
   ```

9. **Verify RPC Services**  

   ```bash
   rpcinfo -p localhost
   ```

   Note down the ports and their types.

10. **Configure Firewall Rules**  
    Adjust the IP range according to your network:

    ```bash
    iptables -I INPUT -m state --state NEW -p tcp -m multiport --dport 111,892,2049,32803 -s 192.168.0.0/24 -j ACCEPT
    iptables -I INPUT -m state --state NEW -p udp -m multiport --dport 111,892,2049,32769 -s 192.168.0.0/24 -j ACCEPT
    ```

11. **Save Firewall Rules**  
    Test from the client side. If successful, save the iptables configuration:

    ```bash
    service iptables save
    ```

## Client Side

1. **Create Mount Point**  

   ```bash
   mkdir /nfs
   ```

2. **Check RPC Services on Server**  

   ```bash
   rpcinfo -p [server_ip]
   ```

3. **Show NFS Exports**  

   ```bash
   showmount -e [server_ip]
   ```

4. **Mount NFS Share**  

   ```bash
   mount -t nfs -o soft,intr,bg,rw [server_ip]:/home/nfs /nfs
   ```

5. **Unmount NFS Share**  

   ```bash
   umount /nfs
   ```

6. **Configure Automatic Mounting**  
   Edit the fstab file:

   ```bash
   vi /etc/fstab
   ```

   Add the following line:

   ```text
   [server_ip]:/home/nfs /nfs nfs soft,intr,bg,rw 0 0
   ```
