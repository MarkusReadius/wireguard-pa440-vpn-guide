# Network Configuration Guide

Guide for configuring network settings for both WireGuard VMs and PA-440 firewalls, with ESXi servers behind physical PA-440s.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Network Overview](#network-overview)
  - [Site Network Allocations](#site-network-allocations)
- [Physical Network Setup](#physical-network-setup)
  - [HQ Site](#hq-site)
  - [Remote Sites](#remote-sites)
- [PA-440 Configuration](#pa-440-configuration)
  - [HQ PA-440 Setup](#hq-pa-440-setup)
  - [Remote Site PA-440 Setup](#remote-site-pa-440-setup)
- [ESXi Network Configuration](#esxi-network-configuration)
  - [1. Virtual Switch Setup](#1-virtual-switch-setup)
  - [2. Port Groups](#2-port-groups)
  - [3. VMkernel Ports](#3-vmkernel-ports)
- [WireGuard VM Configuration](#wireguard-vm-configuration)
  - [HQ WireGuard VM](#hq-wireguard-vm)
  - [Remote Site WireGuard VMs](#remote-site-wireguard-vms)
- [Routing Configuration](#routing-configuration)
  - [HQ Site](#hq-site-1)
  - [Remote Sites](#remote-sites-1)
- [Testing Procedures](#testing-procedures)
  - [1. Basic Connectivity](#1-basic-connectivity)
  - [2. WireGuard Connectivity](#2-wireguard-connectivity)
  - [3. Internal Network Access](#3-internal-network-access)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)
  - [Diagnostic Commands](#diagnostic-commands)

## Network Overview

### Site Network Allocations
```
HQ (10.83.40.0/24) - Internet Gateway:
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.40.1/24
- PA-440 DMZ: 10.83.40.2/24
- ESXi Management: 10.83.40.10/24
- WireGuard VM DMZ IP: 10.83.40.254/24
- Internal Network: 10.83.40.0/24

Site 1 (10.83.10.0/24):
- PA-440 Internal: [INTERNAL_IP]
- PA-440 LAN: 10.83.10.1/24
- PA-440 DMZ: 10.83.10.2/24
- ESXi Management: 10.83.10.10/24
- WireGuard VM DMZ IP: 10.83.10.254/24
- Internal Network: 10.83.10.0/24

Site 2 (10.83.20.0/24):
- PA-440 Internal: [INTERNAL_IP]
- PA-440 LAN: 10.83.20.1/24
- PA-440 DMZ: 10.83.20.2/24
- ESXi Management: 10.83.20.10/24
- WireGuard VM DMZ IP: 10.83.20.254/24
- Internal Network: 10.83.20.0/24

Site 3 (10.83.30.0/24):
- PA-440 Internal: [INTERNAL_IP]
- PA-440 LAN: 10.83.30.1/24
- PA-440 DMZ: 10.83.30.2/24
- ESXi Management: 10.83.30.10/24
- WireGuard VM DMZ IP: 10.83.30.254/24
- Internal Network: 10.83.30.0/24
```

## Physical Network Setup

### HQ Site
1. **Physical Connections**
   ```
   Internet ─── PA-440 WAN
                  │
                  ├── LAN (Internal Network)
                  │   └── ESXi Management
                  │
                  └── DMZ
                      └── WireGuard VM
   ```

### Remote Sites
1. **Physical Connections**
   ```
   Internal Network ─── PA-440 Internal
                          │
                          ├── LAN (Internal Network)
                          │   └── ESXi Management
                          │
                          └── DMZ
                              └── WireGuard VM
   ```

## PA-440 Configuration

### HQ PA-440 Setup

1. **Interface Configuration**
   ```
   ethernet1/1 (WAN):
     Type: Layer3
     Zone: WAN
     IPv4: [EXTERNAL_IP]/[SUBNET]

   ethernet1/2 (LAN):
     Type: Layer3
     Zone: LAN
     IPv4: 10.83.40.1/24

   ethernet1/3 (DMZ):
     Type: Layer3
     Zone: DMZ
     IPv4: 10.83.40.2/24
   ```

2. **Security Zones**
   ```
   WAN:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/1

   LAN:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/2

   DMZ:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/3
   ```

### Remote Site PA-440 Setup

1. **Interface Configuration**
   ```
   ethernet1/1 (Internal):
     Type: Layer3
     Zone: INTERNAL
     IPv4: [INTERNAL_IP]/24

   ethernet1/2 (LAN):
     Type: Layer3
     Zone: LAN
     IPv4: 10.83.x0.1/24

   ethernet1/3 (DMZ):
     Type: Layer3
     Zone: DMZ
     IPv4: 10.83.x0.2/24
   ```

2. **Security Zones**
   ```
   INTERNAL:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/1

   LAN:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/2

   DMZ:
     - Enable: User-ID, Device-ID
     - Interfaces: ethernet1/3
   ```

## ESXi Network Configuration

### 1. Virtual Switch Setup
```
vSwitch0:
  - Management Network (VLAN if needed)
  - VM Network - DMZ
  - VM Network - Internal
```

### 2. Port Groups
```
Management Network:
  - VLAN: [if required]
  - Security: MAC address changes, Forged transmits

DMZ Network:
  - VLAN: [if required]
  - Security: MAC address changes, Promiscuous mode

Internal Network:
  - VLAN: [if required]
  - Security: MAC address changes
```

### 3. VMkernel Ports
```
Management:
  - Network: Management Network
  - IP: 10.83.x0.10/24
  - Gateway: 10.83.x0.1
  - Services: Management
```

## WireGuard VM Configuration

### HQ WireGuard VM
```
DMZ Interface (ens160):
  IP: 10.83.40.254/24
  Gateway: 10.83.40.2
  Routes: Default via PA-440 DMZ

Internal Interface (ens192):
  IP: 10.83.40.253/24
  Routes: Internal networks
```

### Remote Site WireGuard VMs
```
DMZ Interface (ens160):
  IP: 10.83.x0.254/24
  Gateway: 10.83.x0.2
  Routes: Default via PA-440 DMZ

Internal Interface (ens192):
  IP: 10.83.x0.253/24
  Routes: Internal networks
```

## Routing Configuration

### HQ Site
1. **PA-440 Routes**
   ```
   Default Route:
     Next-hop: [ISP_GATEWAY]
     Interface: ethernet1/1

   Internal Routes:
     10.83.10.0/24 via 10.83.40.254
     10.83.20.0/24 via 10.83.40.254
     10.83.30.0/24 via 10.83.40.254
   ```

2. **WireGuard Routes**
   ```
   Default Route:
     via 10.83.40.2

   Static Routes:
     10.83.10.0/24 via wg0
     10.83.20.0/24 via wg0
     10.83.30.0/24 via wg0
   ```

### Remote Sites
1. **PA-440 Routes**
   ```
   Default Route:
     Next-hop: 10.83.x0.254
     Interface: ethernet1/3

   Internal Routes:
     Local network via ethernet1/2
   ```

2. **WireGuard Routes**
   ```
   Default Route:
     via 10.83.x0.2

   Static Routes:
     10.83.40.0/24 via wg0
     [OTHER_SITE_NETWORKS] via wg0
   ```

## Testing Procedures

### 1. Basic Connectivity
```bash
# From WireGuard VMs
ping -c 4 [PA-440_DMZ_IP]
ping -c 4 [PA-440_LAN_IP]

# From ESXi
ping [PA-440_LAN_IP]
ping [INTERNAL_GATEWAY]
```

### 2. WireGuard Connectivity
```bash
# From HQ WireGuard VM
ping -c 4 10.83.10.254  # Site 1
ping -c 4 10.83.20.254  # Site 2
ping -c 4 10.83.30.254  # Site 3

# From Remote WireGuard VMs
ping -c 4 10.83.40.254  # HQ
```

### 3. Internal Network Access
```bash
# From Internal Networks
ping [REMOTE_SITE_INTERNAL_IP]
traceroute [REMOTE_SITE_INTERNAL_IP]
```

## Troubleshooting

### Common Issues

1. **ESXi Management Access**
   - Verify PA-440 LAN interface configuration
   - Check VLAN settings if used
   - Verify management network settings

2. **WireGuard Connectivity**
   - Check PA-440 DMZ interface configuration
   - Verify NAT rules
   - Check routing between DMZ and WAN

3. **Internal Network Access**
   - Verify PA-440 LAN interface configuration
   - Check routing between LAN and DMZ
   - Verify security policies

### Diagnostic Commands
```bash
# From PA-440
ping source [INTERFACE] host [TARGET]
show routing route
show interface logical

# From WireGuard VM
ip route show
traceroute [TARGET]
tcpdump -i wg0

# From ESXi
esxcli network ip interface list
esxcli network ip route list
