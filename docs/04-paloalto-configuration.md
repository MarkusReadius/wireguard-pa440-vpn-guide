# PA-440 Configuration Guide

Quick guide for configuring PA-440 firewalls in a hub-spoke topology where HQ provides internet for all sites.

## HQ PA-440 (Internet Gateway)

### Interface Setup
```
ethernet1/1 (WAN):
  - Layer3, Zone: WAN
  - IP: [EXTERNAL_IP]

ethernet1/2 (LAN):
  - Layer3, Zone: LAN
  - IP: 10.83.40.1/24

ethernet1/3 (DMZ):
  - Layer3, Zone: DMZ
  - IP: 10.83.40.2/24
```

### NAT Rules
```
1. Internet Access (Source NAT):
   - Source: 10.83.0.0/16
   - Destination: any
   - Translation: WAN IP

2. WireGuard Inbound (Destination NAT):
   - Source: any
   - Destination: [WAN_IP], UDP/51820
   - Translation: 10.83.40.254
```

### Security Policies
```
1. Allow Internet:
   - Source: LAN, DMZ
   - Destination: WAN
   - Service: any
   - Action: allow

2. Allow WireGuard:
   - Source: WAN
   - Destination: 10.83.40.254
   - Service: UDP/51820
   - Action: allow

3. Allow Inter-Site:
   - Source: any
   - Destination: 10.83.0.0/16
   - Service: any
   - Action: allow
```

### Routes
```
1. Default Route:
   - 0.0.0.0/0 via [ISP_GATEWAY]

2. Site Routes:
   - 10.83.10.0/24 via 10.83.40.254
   - 10.83.20.0/24 via 10.83.40.254
   - 10.83.30.0/24 via 10.83.40.254
```

## Remote Site PA-440s

### Interface Setup
```
ethernet1/1 (Internal):
  - Layer3, Zone: INTERNAL
  - IP: [INTERNAL_IP]

ethernet1/2 (LAN):
  - Layer3, Zone: LAN
  - IP: 10.83.x0.1/24

ethernet1/3 (DMZ):
  - Layer3, Zone: DMZ
  - IP: 10.83.x0.2/24
```

### NAT Rules
```
1. Local NAT:
   - Source: 10.83.x0.0/24
   - Destination: any
   - Translation: Internal IP
```

### Security Policies
```
1. Allow All Traffic:
   - Source: LAN, DMZ
   - Destination: any
   - Service: any
   - Action: allow

2. Allow WireGuard:
   - Source: any
   - Destination: 10.83.x0.254
   - Service: UDP/51820
   - Action: allow
```

### Routes
```
1. Default Route:
   - 0.0.0.0/0 via 10.83.x0.254 (WireGuard VM)

2. Local Routes:
   - 10.83.x0.0/24 direct
```

## Quick Validation

### 1. Test Internet Access
```
# From HQ
ping source ethernet1/1 host 8.8.8.8

# From Remote Sites
ping source ethernet1/2 host 8.8.8.8
```

### 2. Test WireGuard Access
```
# From all sites
ping source ethernet1/3 host 10.83.40.254
```

### 3. Check NAT
```
> show running nat-policy
> show running security-policy
```

## Common Issues

1. No Internet Access
   - Verify NAT rules
   - Check routes
   - Confirm security policies

2. WireGuard Issues
   - Verify UDP/51820 allowed
   - Check NAT translation
   - Confirm routing to WireGuard VM

3. Inter-Site Issues
   - Verify routes
   - Check security policies
   - Confirm WireGuard connectivity
