# WireGuard Multi-Site VPN Guide

[Previous content up to WireGuard Config section remains exactly the same, including network diagram, IP addresses, VM setup, etc.]

### 4. WireGuard Config

**HQ Config File:**
```bash
# Create /etc/wireguard/wg0.conf
[Interface]
PrivateKey = HQ_PRIVATE_KEY
Address = 10.83.40.254/32
ListenPort = 51820

# Site 1
[Peer]
PublicKey = SITE1_PUBLIC_KEY
# Allow traffic to Site 1's network
AllowedIPs = 10.83.10.0/24

# Site 2
[Peer]
PublicKey = SITE2_PUBLIC_KEY
# Allow traffic to Site 2's network
AllowedIPs = 10.83.20.0/24

# Site 3
[Peer]
PublicKey = SITE3_PUBLIC_KEY
# Allow traffic to Site 3's network
AllowedIPs = 10.83.30.0/24
```

**Site 1 Config File:**
```bash
# Create /etc/wireguard/wg0.conf
[Interface]
PrivateKey = SITE1_PRIVATE_KEY
Address = 10.83.10.254/32
ListenPort = 51820

[Peer]
PublicKey = HQ_PUBLIC_KEY
# Allow traffic to HQ and all other sites
AllowedIPs = 10.83.0.0/16  # Covers all site networks (10.83.x0.0/24)
Endpoint = HQ_PUBLIC_IP:51820
PersistentKeepalive = 25
```

**Site 2 Config File:**
```bash
# Create /etc/wireguard/wg0.conf
[Interface]
PrivateKey = SITE2_PRIVATE_KEY
Address = 10.83.20.254/32
ListenPort = 51820

[Peer]
PublicKey = HQ_PUBLIC_KEY
# Allow traffic to HQ and all other sites
AllowedIPs = 10.83.0.0/16  # Covers all site networks (10.83.x0.0/24)
Endpoint = HQ_PUBLIC_IP:51820
PersistentKeepalive = 25
```

**Site 3 Config File:**
```bash
# Create /etc/wireguard/wg0.conf
[Interface]
PrivateKey = SITE3_PRIVATE_KEY
Address = 10.83.30.254/32
ListenPort = 51820

[Peer]
PublicKey = HQ_PUBLIC_KEY
# Allow traffic to HQ and all other sites
AllowedIPs = 10.83.0.0/16  # Covers all site networks (10.83.x0.0/24)
Endpoint = HQ_PUBLIC_IP:51820
PersistentKeepalive = 25
```

### 5. Start WireGuard

**On All Sites:**
```bash
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

## Traffic Flow

### Internet Access
```
Remote Site -> HQ -> Internet
Example: 10.83.10.0/24 -> 10.83.40.254 -> Internet
```

### Site-to-Site Access
```
Site 1 -> HQ -> Site 2
Example: 10.83.10.0/24 -> 10.83.40.254 -> 10.83.20.0/24

Site 2 -> HQ -> Site 3
Example: 10.83.20.0/24 -> 10.83.40.254 -> 10.83.30.0/24

Site 3 -> HQ -> Site 1
Example: 10.83.30.0/24 -> 10.83.40.254 -> 10.83.10.0/24
```

### Access Summary
- HQ can reach all sites directly (10.83.10.0/24, 10.83.20.0/24, 10.83.30.0/24)
- All sites can reach each other through HQ
- All sites can reach the internet through HQ
- All traffic between sites is encrypted

## Testing

**From Remote Sites:**
```bash
# Test Internet
ping 8.8.8.8

# Test HQ
ping 10.83.40.254

# Test Other Sites
ping 10.83.10.254  # Site 1
ping 10.83.20.254  # Site 2
ping 10.83.30.254  # Site 3

# Test Full Connectivity
for ip in 10.83.{10,20,30,40}.254; do
    echo "Testing connection to $ip..."
    ping -c 4 $ip
done
```

## Common Problems

1. **No Internet Access**
   - Check HQ NAT rules
   - Verify "AllowedIPs = 0.0.0.0/0" on remote sites
   - Check WireGuard status: `sudo wg show`

2. **Can't Connect**
   - Verify UDP/51820 is allowed
   - Check public/private keys match
   - Verify endpoint IP is correct

3. **Sites Can't See Each Other**
   - Check AllowedIPs includes site networks (10.83.0.0/16)
   - Verify routing is enabled
   - Check PA-440 security rules
   - Verify HQ is forwarding traffic between sites

## Quick Fixes

**Restart WireGuard:**
```bash
sudo systemctl restart wg-quick@wg0
```

**Check Status:**
```bash
sudo wg show
sudo systemctl status wg-quick@wg0
```

**View Logs:**
```bash
sudo journalctl -u wg-quick@wg0
```

**Verify Routing:**
```bash
# Check routes
ip route show

# Monitor traffic
sudo tcpdump -i wg0 -n

# Check forwarding
cat /proc/sys/net/ipv4/ip_forward
