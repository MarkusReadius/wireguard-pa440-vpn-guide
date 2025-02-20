# Validation and Troubleshooting Guide

This guide provides comprehensive validation procedures and troubleshooting steps for the WireGuard VPN infrastructure.

## System Validation

### 1. Component Health Check

#### ESXi Host
```bash
# Check VM status
vim-cmd vmsvc/getallvms
vim-cmd vmsvc/power.getstate [vmid]

# Check resource usage
esxtop
```

#### Ubuntu VMs
```bash
# System Status
uptime
free -h
df -h
top

# Service Status
systemctl status wg-quick@wg0
systemctl status networking
```

#### PA-440 Firewalls
```
> show system info
> show system resources
> show interface all
```

### 2. Network Validation

#### Basic Connectivity
```bash
# From WireGuard VMs
ping -c 4 8.8.8.8
ping -c 4 [GATEWAY_IP]
ping -c 4 [PEER_IP]

# From PA-440s
ping source [INTERFACE] host 8.8.8.8
ping source [INTERFACE] host [PEER_IP]
```

#### Route Verification
```bash
# On WireGuard VMs
ip route show
ip route get [DESTINATION_IP]

# On PA-440s
> show routing route
> show routing summary
```

#### Interface Status
```bash
# On WireGuard VMs
ip addr show
ip link show
ethtool [INTERFACE]

# On PA-440s
> show interface logical
> show interface hardware
```

## WireGuard Validation

### 1. Tunnel Status

```bash
# Check WireGuard interface
sudo wg show all

# Expected output format:
interface: wg0
  public key: [KEY]
  private key: (hidden)
  listening port: 51820
  
peer: [PEER_PUBLIC_KEY]
  endpoint: [PEER_IP]:51820
  allowed ips: [NETWORK_RANGE]
  latest handshake: [TIMESTAMP]
  transfer: [RX_BYTES] received, [TX_BYTES] sent
```

### 2. Traffic Flow

```bash
# Monitor WireGuard interface
sudo tcpdump -i wg0 -n

# Monitor specific peer traffic
sudo tcpdump -i wg0 host [PEER_IP] -n

# Check connection tracking
sudo conntrack -L
```

### 3. Performance Testing

```bash
# Bandwidth Test
iperf3 -s                    # Server
iperf3 -c [SERVER_IP]        # Client

# Latency Test
ping -c 100 [PEER_IP] | tail -1

# Path Analysis
mtr -n [DESTINATION_IP]
```

## PA-440 Validation

### 1. Security Policy Verification

```
# Show all security policies
> show security policy all

# Show specific policy hits
> show security policy hit-count

# Monitor real-time traffic
> debug dataplane packet-diag
```

### 2. NAT Rule Verification

```
# Show NAT rules
> show nat all

# Show NAT translations
> show nat translations

# Clear NAT translations
> clear nat translations all
```

### 3. Logging Verification

```
# Show traffic logs
> show log traffic

# Show system logs
> show log system

# Show specific log details
> show log traffic detail
```

## Troubleshooting Procedures

### 1. Connectivity Issues

#### WireGuard Connection Problems
```bash
# Check WireGuard status
sudo systemctl status wg-quick@wg0

# Verify interface
ip addr show wg0

# Check logs
sudo journalctl -u wg-quick@wg0 -n 100

# Restart service
sudo systemctl restart wg-quick@wg0
```

#### Network Path Issues
```bash
# Trace route
traceroute -n [DESTINATION_IP]

# Check MTU
ping -c 4 -M do -s 1500 [PEER_IP]

# Monitor path
mtr -n [DESTINATION_IP]
```

### 2. Performance Issues

#### High Latency
```bash
# Monitor network latency
ping -c 100 [PEER_IP]

# Check system load
top
iostat
vmstat 1

# Monitor interface
iftop -i wg0
```

#### Bandwidth Problems
```bash
# Test bandwidth
iperf3 -c [SERVER_IP] -P 4

# Monitor traffic
nethogs wg0

# Check interface stats
ethtool -S wg0
```

### 3. Routing Issues

#### Route Problems
```bash
# Show routing table
ip route show table all

# Check specific route
ip route get [DESTINATION_IP]

# Monitor routing changes
watch -n1 "ip route show"
```

#### Firewall Issues
```bash
# Check firewall rules
sudo ufw status verbose
sudo iptables -L -n -v

# Monitor dropped packets
sudo tcpdump -i any 'icmp[icmptype] == icmp-unreach'
```

## Common Issues and Solutions

### 1. Tunnel Won't Establish

#### Symptoms
- No handshake in `wg show`
- No traffic flow
- Ping failures

#### Solutions
1. Check UDP port 51820 accessibility
   ```bash
   nc -vuz [PEER_IP] 51820
   ```

2. Verify keys and configurations
   ```bash
   sudo wg showconf wg0
   ```

3. Check NAT traversal
   ```bash
   sudo tcpdump -i any udp port 51820
   ```

### 2. Intermittent Connectivity

#### Symptoms
- Random disconnections
- Variable latency
- Packet loss

#### Solutions
1. Check system resources
   ```bash
   top
   free -h
   ```

2. Monitor interface errors
   ```bash
   watch -n1 "netstat -i"
   ```

3. Verify MTU settings
   ```bash
   ip link set wg0 mtu 1420
   ```

### 3. Performance Degradation

#### Symptoms
- Slow throughput
- High latency
- CPU spikes

#### Solutions
1. Check CPU usage
   ```bash
   mpstat 1
   top -H
   ```

2. Monitor network throughput
   ```bash
   iftop -i wg0
   nethogs wg0
   ```

3. Verify system tuning
   ```bash
   sysctl -a | grep net.ipv4.tcp
   ```

## Validation Checklist

### Initial Setup
- [ ] All VMs running
- [ ] Network interfaces up
- [ ] Basic connectivity established
- [ ] DNS resolution working

### WireGuard Configuration
- [ ] Tunnels established
- [ ] Keys properly configured
- [ ] Routes correctly set
- [ ] Traffic flowing

### PA-440 Configuration
- [ ] Interfaces configured
- [ ] Security policies active
- [ ] NAT rules working
- [ ] Logging enabled

### Performance
- [ ] Bandwidth meets requirements
- [ ] Latency acceptable
- [ ] No packet loss
- [ ] CPU usage normal

## Recovery Procedures

### 1. WireGuard Recovery
```bash
# Stop WireGuard
sudo systemctl stop wg-quick@wg0

# Backup configuration
sudo cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.bak

# Restart service
sudo systemctl start wg-quick@wg0
```

### 2. Network Recovery
```bash
# Reset networking
sudo systemctl restart networking

# Flush routing table
sudo ip route flush table main

# Reload configuration
sudo netplan apply
```

### 3. System Recovery
```bash
# Check system logs
sudo journalctl -xn 500

# Check resource usage
htop

# Restart services
sudo systemctl restart wg-quick@wg0 networking
```

## Monitoring Setup

### 1. System Monitoring
```bash
# Install monitoring tools
sudo apt install -y prometheus node-exporter

# Configure Prometheus
sudo nano /etc/prometheus/prometheus.yml
```

### 2. Network Monitoring
```bash
# Install network monitoring
sudo apt install -y nagios-plugins

# Configure monitoring
sudo nano /etc/nagios/nrpe.cfg
```

### 3. Log Monitoring
```bash
# Configure log rotation
sudo nano /etc/logrotate.d/wireguard

# Setup log monitoring
sudo tail -f /var/log/syslog | grep wg0
```

## Next Steps

1. Document any custom configurations
2. Create backup of working configurations
3. Establish monitoring baseline
4. Schedule regular maintenance
5. Train support staff on troubleshooting procedures
