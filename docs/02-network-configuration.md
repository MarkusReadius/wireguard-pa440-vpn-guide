# Network Configuration Guide

This guide covers the detailed network configuration for both the WireGuard VMs and PA-440 firewalls at each site, with HQ serving as the internet gateway for all sites.

## Network Overview

### Site Network Allocations
```
HQ (10.83.40.0/24) - Internet Gateway:
- PA-440 WAN: [EXTERNAL_IP]
- PA-440 LAN: 10.83.40.1/24
- WireGuard VM WAN: 10.83.40.254/24
- Internal Network: 10.83.40.0/24

Site 1 (10.83.10.0/24):
- PA-440 WAN: [INTERNAL_IP] (No direct internet)
- PA-440 LAN: 10.83.10.1/24
- WireGuard VM WAN: 10.83.10.254/24
- Internal Network: 10.83.10.0/24

Site 2 (10.83.20.0/24):
- PA-440 WAN: [INTERNAL_IP] (No direct internet)
- PA-440 LAN: 10.83.20.1/24
- WireGuard VM WAN: 10.83.20.254/24
- Internal Network: 10.83.20.0/24

Site 3 (10.83.30.0/24):
- PA-440 WAN: [INTERNAL_IP] (No direct internet)
- PA-440 LAN: 10.83.30.1/24
- WireGuard VM WAN: 10.83.30.254/24
- Internal Network: 10.83.30.0/24
```

## HQ (Internet Gateway) PA-440 Configuration

### 1. Interface Configuration

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
IPv4: 10.83.40.1/24
```

#### DMZ Interface (WireGuard)
```
Name: ethernet1/3
Zone: DMZ
Type: Layer3
IPv4: 10.83.40.2/24
```

### 2. NAT Configuration

```
1. Internet Access NAT (for all sites):
   Name: Internet-Access
   Source Zone: LAN, DMZ
   Destination Zone: WAN
   Source Address: 
     - 10.83.40.0/24
     - 10.83.10.0/24
     - 10.83.20.0/24
     - 10.83.30.0/24
   Destination: Any
   Translation: Interface IP

2. WireGuard Inbound NAT:
   Name: WireGuard-Inbound
   Source Zone: WAN
   Destination Zone: DMZ
   Source: Any
   Destination: [EXTERNAL_IP]
   Service: UDP/51820
   Translation: 10.83.40.254
```

### 3. Security Policies

```
1. Allow Internet Access:
   Name: Allow-Internet
   Source Zone: LAN, DMZ
   Destination Zone: WAN
   Source:
     - 10.83.40.0/24
     - 10.83.10.0/24
     - 10.83.20.0/24
     - 10.83.30.0/24
   Destination: Any
   Service: Any
   Action: Allow

2. Allow WireGuard:
   Name: Allow-WireGuard
   Source Zone: WAN
   Destination Zone: DMZ
   Source: Any
   Destination: 10.83.40.254
   Service: UDP/51820
   Action: Allow

3. Allow Inter-Site:
   Name: Allow-InterSite
   Source Zone: DMZ
   Destination Zone: DMZ
   Source: Any
   Destination: Any
   Service: Any
   Action: Allow
```

## Remote Site PA-440 Configuration

### 1. Interface Configuration

#### WAN Interface (Internal Network)
```
Name: ethernet1/1
Zone: WAN
Type: Layer3
IPv4: [INTERNAL_IP]/24
Gateway: [HQ_WIREGUARD_IP]  # Route through WireGuard tunnel
```

#### LAN Interface (Internal)
```
Name: ethernet1/2
Zone: LAN
Type: Layer3
IPv4: [SITE_GATEWAY]/24  # (e.g., 10.83.10.1/24 for Site 1)
```

#### DMZ Interface (WireGuard)
```
Name: ethernet1/3
Zone: DMZ
Type: Layer3
IPv4: [DMZ_NETWORK]/24
```

### 2. Routing Configuration

```
1. Default Route (Internet via HQ):
   Destination: 0.0.0.0/0
   Next Hop: [HQ_WIREGUARD_IP]
   Interface: ethernet1/2

2. Inter-Site Routes:
   Destination: [OTHER_SITE_NETWORKS]
   Next Hop: [HQ_WIREGUARD_IP]
   Interface: ethernet1/2
```

### 3. Security Policies

```
1. Allow All Traffic to HQ:
   Name: Allow-To-HQ
   Source Zone: LAN, DMZ
   Destination Zone: WAN
   Source: [SITE_NETWORK]
   Destination: Any
   Service: Any
   Action: Allow

2. Allow WireGuard:
   Name: Allow-WireGuard
   Source Zone: WAN
   Destination Zone: DMZ
   Source: Any
   Destination: [WIREGUARD_IP]
   Service: UDP/51820
   Action: Allow
```

## WireGuard Configuration

### HQ WireGuard Server
```
[Interface]
PrivateKey = [HQ_PRIVATE_KEY]
Address = 10.83.40.254/32
ListenPort = 51820

# Site 1
[Peer]
PublicKey = [SITE1_PUBLIC_KEY]
AllowedIPs = 10.83.10.0/24
Endpoint = [SITE1_INTERNAL_IP]:51820
PersistentKeepalive = 25

# Site 2
[Peer]
PublicKey = [SITE2_PUBLIC_KEY]
AllowedIPs = 10.83.20.0/24
Endpoint = [SITE2_INTERNAL_IP]:51820
PersistentKeepalive = 25

# Site 3
[Peer]
PublicKey = [SITE3_PUBLIC_KEY]
AllowedIPs = 10.83.30.0/24
Endpoint = [SITE3_INTERNAL_IP]:51820
PersistentKeepalive = 25
```

### Remote Site WireGuard Configuration
```
[Interface]
PrivateKey = [SITE_PRIVATE_KEY]
Address = [SITE_WIREGUARD_IP]/32
ListenPort = 51820

# HQ (Internet Gateway)
[Peer]
PublicKey = [HQ_PUBLIC_KEY]
AllowedIPs = 0.0.0.0/0  # Route all traffic through HQ
Endpoint = [HQ_PUBLIC_IP]:51820
PersistentKeepalive = 25
```

## Testing Procedures

### 1. Basic Connectivity
```bash
# From remote sites to HQ
ping 10.83.40.254

# Internet connectivity through HQ
ping 8.8.8.8

# Inter-site connectivity
ping [OTHER_SITE_IP]
```

### 2. Route Verification
```bash
# Check default route points to HQ
ip route show default

# Verify all traffic routes through HQ
traceroute 8.8.8.8
```

### 3. Bandwidth Testing
```bash
# Test bandwidth to HQ
iperf3 -c 10.83.40.254

# Test internet bandwidth
iperf3 -c [INTERNET_SPEEDTEST_SERVER]
```

## Troubleshooting

### Common Issues

1. **No Internet Access**
   - Verify HQ NAT rules
   - Check routing to HQ
   - Verify WireGuard tunnel status
   - Check HQ's internet connectivity

2. **Inter-Site Issues**
   - Verify routes through HQ
   - Check WireGuard configurations
   - Verify PA-440 security policies
   - Test HQ connectivity first

3. **Performance Issues**
   - Monitor HQ bandwidth utilization
   - Check for bottlenecks
   - Verify MTU settings
   - Consider QoS policies at HQ

## Next Steps

After completing this guide:
1. Verify all sites can reach HQ
2. Test internet access through HQ
3. Validate inter-site connectivity
4. Monitor HQ bandwidth utilization
5. Proceed to [WireGuard Installation](03-wireguard-installation.md)
