# Initial Setup Guide

This guide covers the setup of Ubuntu Server VMs in ESXi for WireGuard VPN deployment.

## ESXi VM Requirements

### Hardware Specifications
- vCPUs: 2
- RAM: 4GB
- Storage: 20GB thin-provisioned
- Network Adapters: 2
  - Adapter 1: WAN (Internet/External)
  - Adapter 2: LAN (Internal Network)

## Step-by-Step VM Creation

1. **Log into ESXi Web Interface**
   - Open browser and navigate to ESXi management IP
   - Login with administrator credentials

2. **Create New Virtual Machine**
   ```
   a. Right-click host → Create/Register VM
   b. Select "Create a new virtual machine"
   c. Click "Next"
   ```

3. **Name and OS Settings**
   ```
   Name: wg-[site]-vpn (e.g., wg-hq-vpn)
   Compatibility: ESXi 7.0 U2 and later
   Guest OS family: Linux
   Guest OS version: Ubuntu Linux (64-bit)
   ```

4. **Storage Selection**
   ```
   Select datastore with sufficient space
   Click "Next"
   ```

5. **Hardware Customization**
   ```
   CPU: 2 vCPU
   Memory: 4 GB
   Hard disk: 20 GB (thin provisioned)
   Network Adapter 1: WAN Network
   Network Adapter 2: LAN Network
   CD/DVD Drive: Ubuntu 22.04 LTS ISO
   ```

6. **Review Settings**
   ```
   Verify all configurations
   Click "Finish"
   ```

## Ubuntu Server Installation

1. **Start VM and Boot from ISO**
   - Power on VM
   - Open console
   - Select "Try or Install Ubuntu Server"

2. **Language and Keyboard**
   ```
   Select language: English
   Select keyboard layout: US
   ```

3. **Network Configuration**
   ```
   ens160 (WAN):
   - DHCP for initial setup
   - Will be configured static later

   ens192 (LAN):
   - No configuration during install
   - Will be configured later
   ```

4. **Storage Configuration**
   ```
   Use entire disk
   Set up as LVM: No
   Confirm write changes
   ```

5. **System Configuration**
   ```
   Your name: WireGuard Admin
   Server name: wg-[site]-vpn
   Username: wgadmin
   Password: [Strong Password]
   ```

6. **SSH Server**
   ```
   Install OpenSSH server: Yes
   Import SSH identity: No
   ```

7. **Featured Server Snaps**
   ```
   Do not select any additional snaps
   ```

8. **Wait for Installation**
   ```
   Allow installation to complete
   Remove installation media
   Reboot when prompted
   ```

## Post-Installation Setup

1. **Update System**
   ```bash
   sudo apt update
   sudo apt upgrade -y
   ```

2. **Install Essential Packages**
   ```bash
   sudo apt install -y \
       net-tools \
       tcpdump \
       iperf3 \
       mtr \
       traceroute
   ```

3. **Disable Automatic Updates**
   ```bash
   sudo nano /etc/apt/apt.conf.d/20auto-upgrades
   ```
   Set both values to 0:
   ```
   APT::Periodic::Update-Package-Lists "0";
   APT::Periodic::Unattended-Upgrade "0";
   ```

4. **Configure Timezone**
   ```bash
   sudo timedatectl set-timezone America/New_York
   ```

5. **Enable IP Forwarding**
   ```bash
   sudo nano /etc/sysctl.conf
   ```
   Uncomment or add:
   ```
   net.ipv4.ip_forward=1
   ```
   Apply changes:
   ```bash
   sudo sysctl -p
   ```

## Network Interface Configuration

1. **Identify Network Interfaces**
   ```bash
   ip a
   ```
   Note which interface is WAN (ens160) and LAN (ens192)

2. **Configure Netplan**
   ```bash
   sudo nano /etc/netplan/00-installer-config.yaml
   ```
   Example configuration:
   ```yaml
   network:
     version: 2
     ethernets:
       ens160:  # WAN Interface
         dhcp4: no
         addresses:
           - [WAN_IP]/24
         routes:
           - to: default
             via: [GATEWAY_IP]
         nameservers:
           addresses: [DNS_SERVERS]
       ens192:  # LAN Interface
         dhcp4: no
         addresses:
           - [LAN_IP]/24
   ```

3. **Apply Network Configuration**
   ```bash
   sudo netplan try
   sudo netplan apply
   ```

## Verification Steps

1. **Check Network Connectivity**
   ```bash
   ping -c 4 8.8.8.8
   ping -c 4 [GATEWAY_IP]
   ```

2. **Verify System Status**
   ```bash
   systemctl status ssh
   sysctl net.ipv4.ip_forward
   ```

3. **Check Interface Configuration**
   ```bash
   ip a
   ip route
   ```

## Next Steps

After completing this guide:
1. Proceed to [Network Configuration](02-network-configuration.md)
2. Document IP addresses and network details
3. Ensure SSH access is working properly

## Troubleshooting

### Common Issues

1. **No Network Connectivity**
   - Verify physical/virtual network connections
   - Check IP configuration
   - Verify gateway settings
   - Check ESXi virtual switch configuration

2. **SSH Access Issues**
   - Verify SSH service is running
   - Check firewall settings
   - Verify network connectivity
   - Confirm correct credentials

3. **System Update Failures**
   - Check internet connectivity
   - Verify DNS settings
   - Try different package mirrors

### Support Commands

```bash
# Network Diagnostics
ip a
ip route
netstat -rn
systemctl status networking

# SSH Diagnostics
systemctl status ssh
sudo tail -f /var/log/auth.log

# System Logs
sudo tail -f /var/log/syslog
