# Validation and Troubleshooting Guide

Comprehensive guide for validating and troubleshooting the WireGuard VPN setup.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Validation Steps](#validation-steps)
  - [1. Physical Connectivity](#1-physical-connectivity)
  - [2. ESXi Access](#2-esxi-access)
  - [3. WireGuard VM Status](#3-wireguard-vm-status)
  - [4. VPN Connectivity](#4-vpn-connectivity)
  - [5. Internet Access](#5-internet-access)
- [Common Issues](#common-issues)
  - [PA-440 Issues](#pa-440-issues)
  - [ESXi Issues](#esxi-issues)
  - [WireGuard Issues](#wireguard-issues)
  - [Network Issues](#network-issues)
- [Diagnostic Tools](#diagnostic-tools)
  - [Network Tools](#network-tools)
  - [System Tools](#system-tools)
  - [Log Files](#log-files)
- [Recovery Procedures](#recovery-procedures)
  - [WireGuard Recovery](#wireguard-recovery)
  - [Network Recovery](#network-recovery)
  - [System Recovery](#system-recovery)

## Validation Steps

### 1. Physical Connectivity
```bash
# Check PA-440 interfaces
ping [PA440_LAN_IP]
ping [PA440_DMZ_IP]

# Verify ESXi connectivity
ping [ESXI_MGMT_IP]
```

### 2. ESXi Access
```bash
# Test ESXi management
curl -k https://[ESXI_MGMT_IP]
ssh root@[ESXI_MGMT_IP]

# Check VM status
esxcli vm process list
```

### 3. WireGuard VM Status
```bash
# Check WireGuard service
systemctl status wg-quick@wg0

# Verify interfaces
ip link show wg0
ip -d link show wg0

# Check routing
ip route show
ip route get 8.8.8.8
```

### 4. VPN Connectivity
```bash
# Check WireGuard peers
sudo wg show

# Test site connectivity
for site in 10 20 30 40; do
    echo "Testing 10.83.${site}.0/24"
    ping -c 4 10.83.${site}.254
    traceroute 10.83.${site}.254
done
```

### 5. Internet Access
```bash
# Test internet connectivity
ping 8.8.8.8
traceroute 8.8.8.8

# Check NAT
sudo tcpdump -i any -n 'port 53'
```

## Common Issues

### PA-440 Issues
1. **NAT Problems**
   ```
   - Check NAT policy hits
   - Verify source/destination translations
   - Monitor traffic logs
   ```

2. **Security Policy Issues**
   ```
   - Review policy order
   - Check policy hits
   - Verify zones and addresses
   ```

3. **Routing Problems**
   ```
   - Verify virtual router configuration
   - Check static routes
   - Test next-hop reachability
   ```

### ESXi Issues
1. **Management Access**
   ```
   - Check network configuration
   - Verify firewall rules
   - Test management interface
   ```

2. **VM Network Issues**
   ```
   - Verify vSwitch configuration
   - Check port group settings
   - Test VM connectivity
   ```

### WireGuard Issues
1. **Tunnel Problems**
   ```bash
   # Check WireGuard status
   sudo wg show
   sudo systemctl status wg-quick@wg0
   
   # View logs
   sudo journalctl -u wg-quick@wg0
   ```

2. **Key Issues**
   ```bash
   # Verify key permissions
   ls -l /etc/wireguard/
   
   # Check key usage
   sudo wg show all dump
   ```

3. **Routing Problems**
   ```bash
   # Check routes
   ip route show table all
   
   # Monitor traffic
   sudo tcpdump -i wg0 -n
   ```

### Network Issues
1. **Connectivity Problems**
   ```bash
   # Test basic connectivity
   ping -c 4 [TARGET_IP]
   
   # Check routes
   ip route get [TARGET_IP]
   
   # Monitor traffic
   sudo tcpdump -i any host [TARGET_IP]
   ```

2. **Performance Issues**
   ```bash
   # Test bandwidth
   iperf3 -c [TARGET_IP]
   
   # Check latency
   mtr -n [TARGET_IP]
   ```

## Diagnostic Tools

### Network Tools
```bash
# Basic connectivity
ping
traceroute
mtr

# Traffic analysis
tcpdump
wireshark

# Bandwidth testing
iperf3
```

### System Tools
```bash
# Process monitoring
top
htop
ps aux

# Resource usage
free -m
df -h
vmstat
```

### Log Files
```bash
# System logs
/var/log/syslog
/var/log/messages

# WireGuard logs
journalctl -u wg-quick@wg0

# ESXi logs
/var/log/vmkernel.log
/var/log/hostd.log
```

## Recovery Procedures

### WireGuard Recovery
1. **Service Recovery**
   ```bash
   sudo systemctl stop wg-quick@wg0
   sudo systemctl start wg-quick@wg0
   sudo systemctl status wg-quick@wg0
   ```

2. **Configuration Recovery**
   ```bash
   # Backup current config
   sudo cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.bak
   
   # Restore from backup
   sudo cp /etc/wireguard/wg0.conf.bak /etc/wireguard/wg0.conf
   ```

### Network Recovery
1. **Interface Recovery**
   ```bash
   # Reset interface
   sudo ip link set wg0 down
   sudo ip link set wg0 up
   
   # Verify status
   ip link show wg0
   ```

2. **Route Recovery**
   ```bash
   # Clear routes
   sudo ip route flush table main
   
   # Restore default configuration
   sudo netplan apply
   ```

### System Recovery
1. **Service Recovery**
   ```bash
   # Restart networking
   sudo systemctl restart systemd-networkd
   
   # Verify status
   systemctl status systemd-networkd
   ```

2. **VM Recovery**
   ```bash
   # From ESXi
   vim-cmd vmsvc/power.off [VMID]
   vim-cmd vmsvc/power.on [VMID]
