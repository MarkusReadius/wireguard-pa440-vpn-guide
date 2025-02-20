# PA-440 Configuration Guide

This guide provides detailed instructions for configuring Palo Alto PA-440 firewalls to support the WireGuard VPN infrastructure.

## Prerequisites

- PA-440 with PAN-OS (latest stable version)
- Network cables and console access
- Basic network information from [Network Configuration Guide](02-network-configuration.md)
- WireGuard VMs configured per previous guides

## Initial Setup

### 1. Basic Configuration

Access the PA-440 management interface:
```
1. Connect console cable
2. Default credentials:
   Username: admin
   Password: admin
3. Configure management interface:
   > configure
   # set deviceconfig system ip-address [MGMT_IP] netmask [NETMASK] default-gateway [GATEWAY]
   # commit
```

### 2. Interface Configuration

#### Physical Interfaces
```
Network > Interfaces > Ethernet
```

1. **WAN Interface (ethernet1/1)**
```
Interface Type: Layer3
Security Zone: WAN
IPv4: [EXTERNAL_IP]/[SUBNET]
Management Profile: ping-only
```

2. **LAN Interface (ethernet1/2)**
```
Interface Type: Layer3
Security Zone: LAN
IPv4: [SITE_GATEWAY]/24  # (e.g., 10.83.40.1/24 for HQ)
Management Profile: ping-only
```

3. **DMZ Interface (ethernet1/3)**
```
Interface Type: Layer3
Security Zone: DMZ
IPv4: [DMZ_NETWORK]/24
Management Profile: ping-only
```

## Security Configuration

### 1. Security Zones

Create three security zones:
```
Network > Zones
```

1. **WAN Zone**
```
Name: WAN
Type: Layer3
Enable User Identification: Yes
```

2. **LAN Zone**
```
Name: LAN
Type: Layer3
Enable User Identification: Yes
```

3. **DMZ Zone**
```
Name: DMZ
Type: Layer3
Enable User Identification: Yes
```

### 2. Security Policies

Configure security policies:
```
Policies > Security
```

1. **Allow Internal to WAN**
```
Name: Allow-Internal-to-WAN
Source Zone: LAN
Source Address: [SITE_NETWORK]
Destination Zone: WAN
Destination Address: any
Application: any
Service: any
Action: Allow
Log at Session End: Yes
```

2. **Allow WireGuard Traffic**
```
Name: Allow-WireGuard
Source Zone: WAN
Source Address: any
Destination Zone: DMZ
Destination Address: [WIREGUARD_IP]
Application: any
Service: service-udp-51820
Action: Allow
Log at Session End: Yes
```

3. **Allow Internal to WireGuard**
```
Name: Allow-Internal-to-WireGuard
Source Zone: LAN
Source Address: [SITE_NETWORK]
Destination Zone: DMZ
Destination Address: [WIREGUARD_IP]
Application: any
Service: any
Action: Allow
Log at Session End: Yes
```

### 3. NAT Configuration

Configure NAT policies:
```
Policies > NAT
```

1. **WAN Outbound NAT**
```
Name: WAN-Outbound
Source Zone: LAN, DMZ
Destination Zone: WAN
Source Address: [SITE_NETWORK]
Destination Address: any
Service: any
Translation:
  - Source Translation: Dynamic IP and Port
  - Translation Type: Interface Address
```

2. **WireGuard Inbound NAT**
```
Name: WireGuard-Inbound
Source Zone: WAN
Destination Zone: DMZ
Source Address: any
Destination Address: [EXTERNAL_IP]
Service: service-udp-51820
Translation:
  - Source Translation: None
  - Destination Translation:
    - Translation Type: Static IP
    - Translated Address: [WIREGUARD_IP]
```

## Routing Configuration

### 1. Virtual Routers

Configure the default virtual router:
```
Network > Virtual Routers > default
```

1. **Static Routes**
```
Destination: 0.0.0.0/0
Interface: ethernet1/1
Next Hop: [ISP_GATEWAY]
```

2. **Internal Routes**
```
# For HQ (10.83.40.0/24)
Destination: 10.83.10.0/24
Interface: ethernet1/2
Next Hop: 10.83.40.254

Destination: 10.83.20.0/24
Interface: ethernet1/2
Next Hop: 10.83.40.254

Destination: 10.83.30.0/24
Interface: ethernet1/2
Next Hop: 10.83.40.254
```

### 2. Route Distribution

Enable route redistribution if using dynamic routing:
```
Network > Virtual Routers > default > Redistribution Profile
```

## Monitoring and Logging

### 1. Log Settings

Configure log forwarding:
```
Device > Log Settings
```

1. **Traffic Logs**
```
Forward to Panorama: Yes (if applicable)
Store Locally: Yes
```

2. **Threat Logs**
```
Forward to Panorama: Yes (if applicable)
Store Locally: Yes
```

### 2. Monitoring Rules

Create monitoring profiles:
```
Network > Monitoring
```

1. **Interface Monitoring**
```
Profile Name: Interface-Monitor
Interfaces: ethernet1/1, ethernet1/2, ethernet1/3
Failure Condition: Any interface down
Action: Generate SNMP trap
```

2. **Path Monitoring**
```
Profile Name: Path-Monitor
Destination: 8.8.8.8
Interval: 10 seconds
Threshold: 3 failures
Action: Generate SNMP trap
```

## High Availability Configuration (Optional)

### 1. HA Interfaces

Configure HA interfaces:
```
Device > High Availability
```

1. **Control Link**
```
Port: HA1-A
IP Address: [HA_IP]/30
Peer IP Address: [PEER_HA_IP]
```

2. **Data Link**
```
Port: HA1-B
IP Address: [HA_DATA_IP]/30
Peer IP Address: [PEER_HA_DATA_IP]
```

### 2. HA Settings

Configure HA parameters:
```
Device > High Availability > Setup
```

1. **General Settings**
```
Group ID: 1
Mode: Active/Passive
Peer HA IP Address: [PEER_MGMT_IP]
```

2. **Election Settings**
```
Device Priority: 100 (primary), 50 (secondary)
Preemptive: Yes
```

## Configuration Templates

### 1. Security Policy Template
```xml
<entry name="Allow-WireGuard">
  <from>
    <member>WAN</member>
  </from>
  <to>
    <member>DMZ</member>
  </to>
  <source>
    <member>any</member>
  </source>
  <destination>
    <member>[WIREGUARD_IP]</member>
  </destination>
  <service>
    <member>service-udp-51820</member>
  </service>
  <application>
    <member>any</member>
  </application>
  <action>allow</action>
  <log-setting>default</log-setting>
</entry>
```

### 2. NAT Rule Template
```xml
<entry name="WireGuard-Inbound">
  <source-translation>
    <none/>
  </source-translation>
  <destination-translation>
    <static-translation>
      <translated-address>[WIREGUARD_IP]</translated-address>
    </static-translation>
  </destination-translation>
  <from>
    <member>WAN</member>
  </from>
  <to>
    <member>DMZ</member>
  </to>
  <source>
    <member>any</member>
  </source>
  <destination>
    <member>[EXTERNAL_IP]</member>
  </destination>
  <service>service-udp-51820</service>
</entry>
```

## Testing and Verification

### 1. Connectivity Tests
```
> ping source [INTERFACE_IP] host [DESTINATION_IP]
> traceroute [DESTINATION_IP]
```

### 2. Policy Tests
```
1. Test WireGuard connectivity:
   > ping source [DMZ_IP] host [WIREGUARD_PEER_IP]

2. Test internal routing:
   > ping source [LAN_IP] host [REMOTE_LAN_IP]
```

### 3. Log Verification
```
Monitor > Traffic
Monitor > System
Monitor > Network
```

## Troubleshooting

### Common Issues

1. **NAT Issues**
   - Verify NAT policy order
   - Check translation rules
   - Monitor traffic logs
   - Test with packet capture

2. **Routing Problems**
   - Verify static routes
   - Check next-hop availability
   - Test path monitoring
   - Verify virtual router configuration

3. **Policy Issues**
   - Check security policy order
   - Verify address objects
   - Monitor traffic logs
   - Test with specific applications

### Diagnostic Commands
```
> show interface ethernet1/1
> show routing route
> show session all
> show nat all
```

## Next Steps

After completing this guide:
1. Verify all firewall configurations
2. Test WireGuard connectivity
3. Validate security policies
4. Proceed to [Testing Environment](05-testing-environment.md)
