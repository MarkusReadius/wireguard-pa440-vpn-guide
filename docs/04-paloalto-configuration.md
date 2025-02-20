# PA-440 Configuration Guide

This guide provides step-by-step instructions for configuring PA-440 firewalls in a hub-and-spoke topology where HQ serves as the internet gateway for all sites.

## HQ (Internet Gateway) Configuration

### Interface Configuration

1. **Navigate to Network > Interfaces**
2. **Configure WAN Interface (ethernet1/1)**
   ```
   Type: Layer3
   Security Zone: WAN (create if needed)
   IPv4: Your external IP address
   ```

3. **Configure LAN Interface (ethernet1/2)**
   ```
   Type: Layer3
   Security Zone: LAN (create if needed)
   IPv4: 10.83.40.1/24
   ```

4. **Configure DMZ Interface (ethernet1/3)**
   ```
   Type: Layer3
   Security Zone: DMZ (create if needed)
   IPv4: 10.83.40.2/24
   ```

### Security Zones

1. **Navigate to Network > Zones**
2. **Create/Verify the following zones:**
   - WAN
   - LAN
   - DMZ

### NAT Rules

1. **Navigate to Policies > NAT**
2. **Create Internet Access NAT Rule:**
   ```
   Name: Internet-Access
   Original Packet:
     Source Zone: LAN, DMZ
     Destination Zone: WAN
     Source Address: 
       - 10.83.40.0/24
       - 10.83.10.0/24
       - 10.83.20.0/24
       - 10.83.30.0/24
     Destination Address: any
   Translated Packet:
     Source Translation: Interface Address
     Interface: ethernet1/1
   ```

3. **Create WireGuard Inbound NAT Rule:**
   ```
   Name: WireGuard-Inbound
   Original Packet:
     Source Zone: WAN
     Destination Zone: DMZ
     Source Address: any
     Destination Address: [Your WAN IP]
     Service: UDP/51820
   Translated Packet:
     Destination Translation: 10.83.40.254
   ```

### Security Policies

1. **Navigate to Policies > Security**
2. **Create Internet Access Policy:**
   ```
   Name: Allow-Internet
   Source Zone: LAN, DMZ
   Destination Zone: WAN
   Source Address:
     - 10.83.40.0/24
     - 10.83.10.0/24
     - 10.83.20.0/24
     - 10.83.30.0/24
   Destination Address: any
   Application: any
   Service: any
   Action: Allow
   ```

3. **Create WireGuard Policy:**
   ```
   Name: Allow-WireGuard
   Source Zone: WAN
   Destination Zone: DMZ
   Source Address: any
   Destination Address: 10.83.40.254
   Application: any
   Service: UDP/51820
   Action: Allow
   ```

4. **Create Inter-Site Policy:**
   ```
   Name: Allow-InterSite
   Source Zone: DMZ
   Destination Zone: DMZ
   Source Address: [All site networks]
   Destination Address: [All site networks]
   Application: any
   Service: any
   Action: Allow
   ```

### Service Objects

1. **Navigate to Objects > Services**
2. **Create WireGuard Service:**
   ```
   Name: service-udp-51820
   Protocol: UDP
   Destination Port: 51820
   ```

### Address Objects

1. **Navigate to Objects > Addresses**
2. **Create network objects for each site:**
   ```
   Name: net-site1
   Type: IP Netmask
   Value: 10.83.10.0/24

   Name: net-site2
   Type: IP Netmask
   Value: 10.83.20.0/24

   Name: net-site3
   Type: IP Netmask
   Value: 10.83.30.0/24

   Name: net-hq
   Type: IP Netmask
   Value: 10.83.40.0/24
   ```

## Remote Site Configuration (Sites 1, 2, and 3)

### Interface Configuration

1. **Navigate to Network > Interfaces**
2. **Configure WAN Interface (ethernet1/1)**
   ```
   Type: Layer3
   Security Zone: WAN
   IPv4: [Internal IP address]
   ```

3. **Configure LAN Interface (ethernet1/2)**
   ```
   Type: Layer3
   Security Zone: LAN
   IPv4: 10.83.x0.1/24 (where x is site number)
   ```

4. **Configure DMZ Interface (ethernet1/3)**
   ```
   Type: Layer3
   Security Zone: DMZ
   IPv4: 10.83.x0.2/24 (where x is site number)
   ```

### Security Policies

1. **Navigate to Policies > Security**
2. **Create HQ Access Policy:**
   ```
   Name: Allow-To-HQ
   Source Zone: LAN, DMZ
   Destination Zone: WAN
   Source Address: [Local network]
   Destination Address: any
   Application: any
   Service: any
   Action: Allow
   ```

3. **Create WireGuard Policy:**
   ```
   Name: Allow-WireGuard
   Source Zone: WAN
   Destination Zone: DMZ
   Source Address: any
   Destination Address: [Local WireGuard IP]
   Application: any
   Service: UDP/51820
   Action: Allow
   ```

### NAT Configuration

1. **Navigate to Policies > NAT**
2. **Create Local NAT Rule:**
   ```
   Name: Local-NAT
   Original Packet:
     Source Zone: LAN, DMZ
     Destination Zone: WAN
     Source Address: [Local network]
     Destination Address: any
   Translated Packet:
     Source Translation: Interface Address
     Interface: ethernet1/2
   ```

### Routing Configuration

1. **Navigate to Network > Virtual Routers**
2. **Configure default route to HQ:**
   ```
   Destination: 0.0.0.0/0
   Interface: ethernet1/2
   Next Hop: 10.83.40.254
   ```

3. **Add routes for other sites:**
   ```
   Destination: [Other site networks]
   Interface: ethernet1/2
   Next Hop: 10.83.40.254
   ```

## Validation Steps

1. **Test Basic Connectivity**
   ```
   - Ping from remote sites to HQ WireGuard IP
   - Verify NAT translations
   - Check security policy hits
   ```

2. **Test Internet Access**
   ```
   - Verify remote sites can reach internet through HQ
   - Check NAT translations at HQ
   - Monitor traffic logs
   ```

3. **Test Inter-Site Communication**
   ```
   - Verify connectivity between all sites
   - Check routing table
   - Monitor traffic flow
   ```

## Important Notes

1. **Order of Implementation**
   - Configure HQ first
   - Test HQ internet connectivity
   - Configure remote sites one at a time
   - Test each site after configuration

2. **Security Considerations**
   - Review existing security policies
   - Ensure no conflicts with existing rules
   - Monitor logs during initial deployment

3. **Troubleshooting**
   - Check security policy hits
   - Verify NAT translations
   - Review traffic logs
   - Test connectivity at each hop

4. **Maintenance**
   - Document all configurations
   - Regular policy review
   - Monitor bandwidth usage
   - Keep logs for analysis

## Next Steps

After completing PA-440 configuration:
1. Verify all firewalls can communicate
2. Test internet access through HQ
3. Validate inter-site connectivity
4. Proceed to [Testing Environment](05-testing-environment.md)
