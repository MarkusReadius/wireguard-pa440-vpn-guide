# WireGuard Installation Guide

Quick guide for installing and configuring WireGuard VPN on Ubuntu Server VMs.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Installation](#installation)
- [Key Generation](#key-generation)
- [Configuration](#configuration)
  - [HQ Configuration](#hq-configuration)
  - [Remote Site Configuration](#remote-site-configuration)
- [Start WireGuard](#start-wireguard)
- [Quick Tests](#quick-tests)
- [Common Issues](#common-issues)

## Installation

```bash
# Install WireGuard
sudo apt update
sudo apt install -y wireguard wireguard-tools

# Enable IP forwarding
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Key Generation

```bash
# Create WireGuard directory
sudo mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate keys
wg genkey | sudo tee privatekey | wg pubkey | sudo tee publickey
sudo chmod 600 privatekey
```

## Configuration

### HQ Configuration
```ini
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = [HQ_PRIVATE_KEY]
Address = 10.83.40.254/32
ListenPort = 51820

# Site 1
[Peer]
PublicKey = [SITE1_PUBLIC_KEY]
AllowedIPs = 10.83.10.0/24
Endpoint = [SITE1_IP]:51820
PersistentKeepalive = 25

# Site 2
[Peer]
PublicKey = [SITE2_PUBLIC_KEY]
AllowedIPs = 10.83.20.0/24
Endpoint = [SITE2_IP]:51820
PersistentKeepalive = 25

# Site 3
[Peer]
PublicKey = [SITE3_PUBLIC_KEY]
AllowedIPs = 10.83.30.0/24
Endpoint = [SITE3_IP]:51820
PersistentKeepalive = 25
```

### Remote Site Configuration
```ini
# /etc/wireguard/wg0.conf
[Interface]
PrivateKey = [SITE_PRIVATE_KEY]
Address = 10.83.x0.254/32
ListenPort = 51820

# HQ
[Peer]
PublicKey = [HQ_PUBLIC_KEY]
AllowedIPs = 0.0.0.0/0  # Route all traffic through HQ
Endpoint = [HQ_PUBLIC_IP]:51820
PersistentKeepalive = 25
```

## Start WireGuard

```bash
# Enable and start
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0

# Check status
sudo wg show
```

## Quick Tests

```bash
# Check interface
ip a show wg0

# Test connectivity
ping 10.83.40.254  # HQ
ping 8.8.8.8       # Internet (through HQ)

# Show connections
sudo wg show
```

## Common Issues

1. Connection Problems
   ```bash
   # Check WireGuard status
   sudo systemctl status wg-quick@wg0
   
   # View logs
   sudo journalctl -u wg-quick@wg0
   
   # Restart service
   sudo systemctl restart wg-quick@wg0
   ```

2. Routing Issues
   ```bash
   # Check routes
   ip route show
   
   # Monitor traffic
   sudo tcpdump -i wg0
   ```

3. Key Problems
   ```bash
   # Verify keys
   sudo cat /etc/wireguard/publickey
   sudo wg show
