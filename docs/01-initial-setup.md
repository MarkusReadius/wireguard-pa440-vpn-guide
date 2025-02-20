# Initial Setup Guide

Guide for configuring WireGuard VPN VMs in an existing ESXi environment behind PA-440 firewalls.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Network Topology](#network-topology)
- [Prerequisites](#prerequisites)
- [Network Requirements](#network-requirements)
- [VM Network Configuration](#vm-network-configuration)
- [WireGuard VM Requirements](#wireguard-vm-requirements)
- [Network Interface Configuration](#network-interface-configuration)
- [Security Considerations](#security-considerations)
- [Verification Steps](#verification-steps)
- [Next Steps](#next-steps)

## Network Topology

Each site consists of:
1. Physical PA-440 firewall with internet connectivity (HQ) or internal connectivity (other sites)
2. ESXi server in the internal network/DMZ
3. WireGuard VM running on ESXi

## Prerequisites

1. **Existing Infrastructure**
   - ESXi 7.0+ installed and configured
   - Ubuntu Server 22.04 LTS VM deployed
   - PA-440 firewalls configured with basic connectivity

2. **Network Access**
   - ESXi management access
   - PA-440 management access
   - Inter-site connectivity

## Network Requirements

1. **Network Segments**
   ```
   HQ:
   - DMZ: 10.83.40.0/24
   - Management: Protected network
   - WireGuard: DMZ network

   Remote Sites:
   - DMZ: 10.83.x0.0/24
   - Management: Protected network
   - WireGuard: DMZ network
   ```

2. **Required Ports**
   ```
   - UDP 51820 (WireGuard)
   - Management ports protected
   ```

## VM Network Configuration

1. **Network Adapters**
   ```
   Adapter 1 (DMZ):
   - Network: DMZ Port Group
   - Type: VMXNET3
   - IP: x0.254/24

   Adapter 2 (Internal):
   - Network: Internal Port Group
   - Type: VMXNET3
   - IP: x0.253/24
   ```

2. **Port Groups**
   ```
   DMZ Network:
   - VLAN: As required
   - Security: Promiscuous Mode allowed
   - Forged transmits: As needed

   Internal Network:
   - VLAN: As required
   - Standard security
   ```

## WireGuard VM Requirements

1. **System Resources**
   ```
   CPU: 2 vCPU
   RAM: 4GB
   Storage: 20GB thin-provisioned
   Network: 2 adapters (DMZ + Internal)
   ```

2. **Network Configuration**
   ```
   DMZ Interface:
   - IP: 10.83.x0.254/24
   - Gateway: 10.83.x0.2
   - Routes: Default via PA-440

   Internal Interface:
   - IP: 10.83.x0.253/24
   - No default gateway
   - Routes: Internal networks
   ```

## Network Interface Configuration

1. **Configure Netplan**
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

2. **Enable IP Forwarding**
   ```bash
   # Add to /etc/sysctl.conf
   net.ipv4.ip_forward=1

   # Apply changes
   sudo sysctl -p
   ```

## Security Considerations

1. **Network Security**
   ```
   - DMZ isolation
   - Protected management
   - Restricted access
   - Secure protocols
   ```

2. **VM Security**
   ```
   - Minimal services
   - Regular updates
   - Secure configurations
   - Monitoring enabled
   ```

## Verification Steps

1. **Network Connectivity**
   ```bash
   # Test DMZ connectivity
   ping -c 4 [PA440_DMZ_IP]
   
   # Test internal connectivity
   ping -c 4 [INTERNAL_GATEWAY]
   ```

2. **Route Verification**
   ```bash
   # Check routing
   ip route show
   
   # Verify forwarding
   sysctl net.ipv4.ip_forward
   ```

## Next Steps

1. Proceed to [Network Configuration](02-network-configuration.md)
2. Document IP addresses and network details
3. Prepare for WireGuard configuration
