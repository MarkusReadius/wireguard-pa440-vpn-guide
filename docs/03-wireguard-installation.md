# WireGuard Installation and Configuration Guide

This guide covers the installation, configuration, and key management for WireGuard VPN on each site's Ubuntu Server VM.

## Prerequisites

- Ubuntu Server 22.04 LTS
- Network configured per [Network Configuration Guide](02-network-configuration.md)
- Root or sudo access
- Internet connectivity

## Installation

### 1. Install WireGuard
```bash
# Update package list
sudo apt update

# Install WireGuard and tools
sudo apt install -y wireguard wireguard-tools

# Verify installation
wg --version
```

### 2. Generate Keys

Generate keys for each site:
```bash
# Create WireGuard configuration directory
sudo mkdir -p /etc/wireguard
cd /etc/wireguard

# Generate private key
wg genkey | sudo tee privatekey | wg pubkey | sudo tee publickey

# Set secure permissions
sudo chmod 600 privatekey
sudo chmod 644 publickey

# Display public key (needed for peer configuration)
sudo cat publickey
```

## Configuration

### 1. Create WireGuard Interface

Create configuration file for each site:
```bash
sudo nano /etc/wireguard/wg0.conf
```

#### HQ Configuration Example
```ini
[Interface]
PrivateKey = [HQ_PRIVATE_KEY]
Address = 10.83.40.254/32
ListenPort = 51820

# Site 1
[Peer]
PublicKey = [SITE1_PUBLIC_KEY]
AllowedIPs = 10.83.10.0/24
Endpoint = [SITE1_PUBLIC_IP]:51820
PersistentKeepalive = 25

# Site 2
[Peer]
PublicKey = [SITE2_PUBLIC_KEY]
AllowedIPs = 10.83.20.0/24
Endpoint = [SITE2_PUBLIC_IP]:51820
PersistentKeepalive = 25

# Site 3
[Peer]
PublicKey = [SITE3_PUBLIC_KEY]
AllowedIPs = 10.83.30.0/24
Endpoint = [SITE3_PUBLIC_IP]:51820
PersistentKeepalive = 25
```

#### Site 1 Configuration Example
```ini
[Interface]
PrivateKey = [SITE1_PRIVATE_KEY]
Address = 10.83.10.254/32
ListenPort = 51820

# HQ
[Peer]
PublicKey = [HQ_PUBLIC_KEY]
AllowedIPs = 10.83.40.0/24
Endpoint = [HQ_PUBLIC_IP]:51820
PersistentKeepalive = 25

# Site 2
[Peer]
PublicKey = [SITE2_PUBLIC_KEY]
AllowedIPs = 10.83.20.0/24
Endpoint = [SITE2_PUBLIC_IP]:51820
PersistentKeepalive = 25

# Site 3
[Peer]
PublicKey = [SITE3_PUBLIC_KEY]
AllowedIPs = 10.83.30.0/24
Endpoint = [SITE3_PUBLIC_IP]:51820
PersistentKeepalive = 25
```

### 2. Configuration Parameters Explained

```ini
[Interface]
# Your WireGuard interface configuration
PrivateKey = Base64 private key
Address = Local WireGuard IP address
ListenPort = UDP port (default 51820)

[Peer]
# Remote peer configuration
PublicKey = Peer's public key
AllowedIPs = Networks routed through this peer
Endpoint = Peer's public IP and port
PersistentKeepalive = Keep connection alive interval
```

### 3. Enable IP Forwarding

```bash
# Enable IP forwarding
sudo nano /etc/sysctl.conf

# Add or uncomment:
net.ipv4.ip_forward=1

# Apply changes
sudo sysctl -p
```

### 4. Start WireGuard

```bash
# Enable WireGuard service
sudo systemctl enable wg-quick@wg0

# Start WireGuard
sudo systemctl start wg-quick@wg0

# Check status
sudo systemctl status wg-quick@wg0
```

## Testing and Verification

### 1. Check Interface Status
```bash
# Show WireGuard interface
sudo wg show

# Check interface status
ip a show wg0

# View routing table
ip route
```

### 2. Test Connectivity
```bash
# Ping other sites
ping -c 4 10.83.40.254  # HQ
ping -c 4 10.83.10.254  # Site 1
ping -c 4 10.83.20.254  # Site 2
ping -c 4 10.83.30.254  # Site 3

# Test bandwidth (if iperf3 is installed)
# On server:
iperf3 -s
# On client:
iperf3 -c [SERVER_IP]
```

### 3. Monitor Connections
```bash
# Watch WireGuard status
watch sudo wg

# Monitor interface traffic
sudo tcpdump -i wg0

# Check system logs
sudo journalctl -u wg-quick@wg0
```

## Security Considerations

### 1. Key Management
- Store private keys securely
- Backup keys safely
- Rotate keys periodically
- Document key assignments

### 2. Firewall Rules
```bash
# Allow WireGuard traffic
sudo ufw allow 51820/udp

# Allow forwarded traffic
sudo ufw route allow in on wg0 out on ens160
sudo ufw route allow in on ens160 out on wg0
```

### 3. Regular Maintenance
```bash
# Update WireGuard
sudo apt update
sudo apt upgrade wireguard wireguard-tools

# Check logs for issues
sudo journalctl -u wg-quick@wg0 --since "24 hours ago"
```

## Troubleshooting

### Common Issues

1. **Connection Problems**
   - Verify public IPs and ports
   - Check firewall rules
   - Verify key pairs
   - Test underlying network

2. **Routing Issues**
   - Verify AllowedIPs configuration
   - Check IP forwarding
   - Verify route tables
   - Test with traceroute

3. **Performance Issues**
   - Check MTU settings
   - Monitor bandwidth
   - Verify network latency
   - Check system resources

### Diagnostic Commands
```bash
# Connection Status
sudo wg show all
sudo systemctl status wg-quick@wg0

# Network Tests
mtr [PEER_IP]
sudo tcpdump -i wg0
ping -c 4 [PEER_IP]

# Route Verification
ip route show table all
sudo wg showconf wg0
```

## Configuration Templates

### Key Generation Script
```bash
#!/bin/bash
# Generate WireGuard key pair
private_key=$(wg genkey)
public_key=$(echo "$private_key" | wg pubkey)
echo "Private key: $private_key"
echo "Public key: $public_key"
```

### Quick Configuration Script
```bash
#!/bin/bash
# Usage: ./configure-wg.sh [site_number] [public_ip]
SITE=$1
IP=$2

# Generate keys
private_key=$(wg genkey)
public_key=$(echo "$private_key" | wg pubkey)

# Create config file
cat > wg0.conf << EOF
[Interface]
PrivateKey = $private_key
Address = 10.83.${SITE}0.254/32
ListenPort = 51820

# Add peer configurations here
EOF

echo "Configuration created with:"
echo "Public key: $public_key"
echo "IP: 10.83.${SITE}0.254"
```

## Next Steps

After completing this guide:
1. Verify all sites can communicate
2. Document all configurations
3. Test failover scenarios
4. Proceed to [PA-440 Configuration](04-paloalto-configuration.md)
