# Network Configuration Guide

This guide covers the detailed network configuration for both the WireGuard VMs and PA-440 firewalls at each site.

## Network Overview

### Site Network Allocations
```
HQ (10.83.40.0/24):
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.40.1/24
- WireGuard VM WAN: 10.83.40.254/24
- Internal Network: 10.83.40.0/24

Site 1 (10.83.10.0/24):
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.10.1/24
- WireGuard VM WAN: 10.83.10.254/24
- Internal Network: 10.83.10.0/24

Site 2 (10.83.20.0/24):
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.20.1/24
- WireGuard VM WAN: 10.83.20.254/24
- Internal Network: 10.83.20.0/24

Site 3 (10.83.30.0/24):
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.30.1/24
- WireGuard VM WAN: 10.83.30.254/24
- Internal Network: 10.83.30.0/24
```

## PA-440 Initial Configuration

### 1. Basic Setup
```
1. Connect to PA-440 console
2. Initial configuration:
   - Management IP
   - Default gateway
   - DNS servers
   - Administrator password
```

### 2. Interface Configuration

#### WAN Interface (Internet)
```
Name: ethernet1/1
Zone: WAN
Type: Layer3
IPv4: [EXTERNAL_IP]/[SUBNET]
Gateway: [ISP_GATEWAY]
```

#### LAN Interface (Internal)
```
Name: ethernet1/2
Zone: LAN
Type: Layer3
IPv4: [SITE_GATEWAY]/24  # (e.g., 10.83.40.1/24 for HQ)
```

#### DMZ Interface (WireGuard)
```
Name: ethernet1/3
Zone: DMZ
Type: Layer3
IPv4: [DMZ_NETWORK]/24
```

### 3. Security Zones
```
1. WAN Zone:
   - Type: Layer3
   - Enable: User-ID, Device-ID

2. LAN Zone:
   - Type: Layer3
   - Enable: User-ID, Device-ID

3. DMZ Zone:
   - Type: Layer3
   - Enable: User-ID, Device-ID
```

### 4. NAT Rules

#### WAN Outbound NAT
```
Name: WAN-Outbound
Source Zone: LAN, DMZ
Destination Zone: WAN
Source Address: [SITE_NETWORK]
Destination Address: Any
Service: Any
Translation Type: Dynamic IP And Port
Translation Address: [EXTERNAL_IP]
```

#### WireGuard Inbound NAT
```
Name: WireGuard-Inbound
Source Zone: WAN
Destination Zone: DMZ
Source Address: Any
Destination Address: [EXTERNAL_IP]
Service: UDP/51820
Translation Type: Static IP
Translation Address: [WIREGUARD_IP]
```

### 5. Security Policies

#### Internal to WAN
```
Name: Allow-Internal-to-WAN
Source Zone: LAN
Destination Zone: WAN
Source Address: [SITE_NETWORK]
Destination Address: Any
Application: Any
Service: Any
Action: Allow
```

#### WireGuard Traffic
```
Name: Allow-WireGuard
Source Zone: WAN
Destination Zone: DMZ
Source Address: Any
Destination Address: [WIREGUARD_IP]
Application: Any
Service: UDP/51820
Action: Allow
```

#### Internal to WireGuard
```
Name: Allow-Internal-to-WireGuard
Source Zone: LAN
Destination Zone: DMZ
Source Address: [SITE_NETWORK]
Destination Address: [WIREGUARD_IP]
Application: Any
Service: Any
Action: Allow
```

## WireGuard VM Network Configuration

### 1. Interface Configuration

Edit the Netplan configuration:
```bash
sudo nano /etc/netplan/00-installer-config.yaml
```

Example configuration for HQ:
```yaml
network:
  version: 2
  ethernets:
    ens160:  # WAN Interface
      dhcp4: no
      addresses:
        - 10.83.40.254/24  # WireGuard VM IP
      routes:
        - to: default
          via: 10.83.40.1   # PA-440 LAN IP
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
    ens192:  # LAN Interface
      dhcp4: no
      addresses:
        - 10.83.40.253/24  # Internal network IP
```

Apply the configuration:
```bash
sudo netplan try
sudo netplan apply
```

### 2. Routing Configuration

Add static routes for other sites:
```bash
# Example for HQ - Add to /etc/netplan/00-installer-config.yaml
network:
  version: 2
  ethernets:
    ens160:
      routes:
        - to: 10.83.10.0/24  # Site 1
          via: 10.83.40.1
        - to: 10.83.20.0/24  # Site 2
          via: 10.83.40.1
        - to: 10.83.30.0/24  # Site 3
          via: 10.83.40.1
```

### 3. Firewall Configuration

Configure UFW (Uncomplicated Firewall):
```bash
# Enable UFW
sudo ufw enable

# Allow SSH
sudo ufw allow 22/tcp

# Allow WireGuard
sudo ufw allow 51820/udp

# Allow internal network traffic
sudo ufw allow from 10.83.0.0/16

# Enable forwarding
sudo nano /etc/ufw/sysctl.conf
# Uncomment:
# net/ipv4/ip_forward=1
```

## Testing Network Configuration

### 1. Basic Connectivity
```bash
# Test internal network
ping -c 4 [PA-440_LAN_IP]

# Test internet connectivity
ping -c 4 8.8.8.8

# Test DNS resolution
nslookup google.com
```

### 2. Routing Verification
```bash
# Display routing table
ip route

# Check forwarding
sysctl net.ipv4.ip_forward

# Verify interfaces
ip addr show
```

### 3. Firewall Rules
```bash
# Check UFW status
sudo ufw status verbose

# Verify PA-440 NAT rules
# Access PA-440 web interface
# Monitor > System > Traffic
```

## Troubleshooting

### Common Issues

1. **No Internet Access**
   - Verify PA-440 WAN configuration
   - Check NAT rules
   - Verify default gateway
   - Check DNS settings

2. **Internal Network Issues**
   - Verify interface configurations
   - Check routing tables
   - Verify firewall rules
   - Test connectivity between segments

3. **Routing Problems**
   - Verify static routes
   - Check forwarding settings
   - Verify PA-440 routing configuration
   - Test path with traceroute

### Diagnostic Commands
```bash
# Network Connectivity
ping -c 4 [TARGET_IP]
traceroute [TARGET_IP]
mtr [TARGET_IP]

# Interface Status
ip addr show
ip link show
ethtool [INTERFACE]

# Routing
ip route show
ip route get [TARGET_IP]

# Firewall
sudo ufw status verbose
sudo iptables -L -n -v
```

## Next Steps

After completing this guide:
1. Verify all network configurations
2. Document all IP addresses and routes
3. Test connectivity between sites
4. Proceed to [WireGuard Installation](03-wireguard-installation.md)
