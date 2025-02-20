# Technical Context and Requirements

## Core Technologies

### Virtualization Platform
- VMware ESXi (latest stable version)
- Virtual Machine Specifications:
  - CPU: 2 vCPU minimum
  - RAM: 4GB minimum
  - Storage: 20GB minimum
  - Network: 2 vNIC minimum (WAN + LAN)

### Operating System
- Ubuntu Server 22.04 LTS
- Minimal installation
- Server-only packages
- Regular security updates enabled

### WireGuard
- Version: Latest stable from Ubuntu repositories
- Kernel module requirements:
  - Linux kernel 5.6 or newer (built-in support)
  - wireguard-tools package

### Firewall
- Palo Alto Networks PA-440
- PAN-OS: Latest stable version
- Minimum required interfaces:
  - WAN interface (Internet)
  - LAN interface (Internal network)
  - DMZ interface (WireGuard VM)

## Network Requirements

### Bandwidth
- Minimum: 10 Mbps symmetric
- Recommended: 100 Mbps symmetric
- MTU considerations for WireGuard: 1420 bytes

### IP Addressing
```
Site Allocations:
- HQ:    10.83.40.0/24
- Site 1: 10.83.10.0/24
- Site 2: 10.83.20.0/24
- Site 3: 10.83.30.0/24

WireGuard Interface Addressing:
- HQ:    10.83.40.254/32
- Site 1: 10.83.10.254/32
- Site 2: 10.83.20.254/32
- Site 3: 10.83.30.254/32
```

### Port Requirements
- WireGuard: UDP 51820
- SSH (management): TCP 22
- ICMP (monitoring)

## Development Environment

### Required Tools
- SSH client
- WireGuard tools
- Network debugging tools:
  - tcpdump
  - ping
  - traceroute
  - mtr
  - iperf3

### Testing Environment
- Isolated network segment
- Single internet-connected PA-440
- Virtual network for simulating multi-site connectivity

## Security Requirements

### Encryption
- WireGuard default cryptography:
  - ChaCha20 for symmetric encryption
  - Poly1305 for authentication
  - Curve25519 for ECDH
  - BLAKE2s for hashing
  - SipHash24 for hashtable keys

### Key Management
- Private keys: 256-bit private keys
- Public keys: 256-bit public keys
- Pre-shared keys (optional): 256-bit
- Key storage: Secure directory permissions (600)

### Firewall Policies
- Minimum required rules:
  - Allow WireGuard UDP port
  - Allow internal network routing
  - Allow management access
  - Default deny all

## Monitoring Requirements

### Health Checks
- ICMP monitoring between sites
- Interface status monitoring
- Bandwidth utilization
- Latency monitoring
- Packet loss detection

### Logging
- WireGuard connection status
- Firewall logs
- System logs
- Performance metrics

## Backup Requirements

### Configuration Backup
- WireGuard configs
- Firewall configs
- Network configs
- Key material
- Documentation

### Recovery Procedures
- Step-by-step restoration guides
- Configuration templates
- Emergency contact information
- Rollback procedures
