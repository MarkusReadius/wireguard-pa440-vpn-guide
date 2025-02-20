# Initial Setup Guide

This guide covers the setup of Ubuntu Server VMs in ESXi for WireGuard VPN deployment, where ESXi servers are located behind physical PA-440 firewalls.

## Network Topology

Each site consists of:
1. Physical PA-440 firewall with internet connectivity (HQ) or internal connectivity (other sites)
2. ESXi server in the internal network/DMZ
3. WireGuard VM running on ESXi

## ESXi Server Requirements

### Hardware Specifications
- CPU: Sufficient for virtualization
- RAM: 16GB minimum recommended
- Storage: 100GB minimum
- Network: 1Gbps minimum

### Network Location
- ESXi management interface should be in protected network segment
- VM network must be accessible through PA-440 DMZ interface
- Physical network adapters should be properly segregated

## ESXi Installation

1. **Physical Setup**
   ```
   - Install ESXi on server hardware
   - Configure management network in protected segment
   - Ensure connectivity through PA-440 internal interface
   ```

2. **Network Configuration**
   ```
   - Create VM Network for WireGuard (DMZ segment)
   - Create Management Network (protected segment)
   - Configure VLANs if needed
   ```

3. **Security Configuration**
   ```
   - Disable unnecessary services
   - Configure firewall rules
   - Set up secure management access
   ```

## WireGuard VM Requirements

### Hardware Specifications
- vCPUs: 2
- RAM: 4GB
- Storage: 20GB thin-provisioned
- Network Adapters: 2
  - Adapter 1: DMZ Network (WireGuard traffic)
  - Adapter 2: Internal Network (Local routing)

## Step-by-Step VM Creation

1. **Log into ESXi Web Interface**
   - Access ESXi management IP through PA-440 internal network
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
   Network Adapter 1: DMZ Network
   Network Adapter 2: Internal Network
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
   ens160 (DMZ):
   - Configure static IP in DMZ segment
   - Gateway will be PA-440 DMZ interface

   ens192 (Internal):
   - Configure static IP in internal segment
   - No default gateway on this interface
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

3. **Configure Timezone**
   ```bash
   sudo timedatectl set-timezone America/New_York
   ```

4. **Enable IP Forwarding**
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
   Note which interface is DMZ (ens160) and Internal (ens192)

2. **Configure Netplan**
   ```bash
   sudo nano /etc/netplan/00-installer-config.yaml
   ```
   Example configuration:
   ```yaml
   network:
     version: 2
     ethernets:
       ens160:  # DMZ Interface
         dhcp4: no
         addresses:
           - [DMZ_IP]/24
         routes:
           - to: default
             via: [PA440_DMZ_IP]
         nameservers:
           addresses: [DNS_SERVERS]
       ens192:  # Internal Interface
         dhcp4: no
         addresses:
           - [INTERNAL_IP]/24
   ```

3. **Apply Network Configuration**
   ```bash
   sudo netplan try
   sudo netplan apply
   ```

## Security Considerations

1. **ESXi Security**
   - Place management interface in protected network
   - Configure ESXi firewall to restrict access
   - Use secure protocols (HTTPS, SSH)
   - Regular security patches

2. **VM Network Security**
   - Isolate DMZ and Internal networks
   - Use separate port groups
   - Configure proper VLAN segregation
   - Monitor traffic between segments

## Verification Steps

1. **Check Network Connectivity**
   ```bash
   # Test DMZ connectivity
   ping -c 4 [PA440_DMZ_IP]
   
   # Test internal connectivity
   ping -c 4 [INTERNAL_GATEWAY]
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
   - Verify PA-440 DMZ configuration
   - Check ESXi virtual switch settings
   - Verify VM network adapter settings
   - Check Ubuntu network configuration

2. **SSH Access Issues**
   - Verify SSH service is running
   - Check PA-440 security policies
   - Verify network connectivity
   - Confirm correct credentials

3. **System Update Failures**
   - Check PA-440 outbound policies
   - Verify DNS settings
   - Configure proxy if needed

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
