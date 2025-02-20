# Testing Environment Guide

Guide for validating the WireGuard VPN setup in a test environment where only HQ has internet access.

## Table of Contents
- [Table of Contents](#table-of-contents)
- [Test Environment Architecture](#test-environment-architecture)
- [Network Flow](#network-flow)
- [Validation Steps](#validation-steps)
  - [1. Internet Gateway (HQ)](#1-internet-gateway-hq)
  - [2. WireGuard Tunnels](#2-wireguard-tunnels)
  - [3. Inter-Site Communication](#3-inter-site-communication)
- [Performance Testing](#performance-testing)
  - [1. Bandwidth Test](#1-bandwidth-test)
  - [2. Latency Test](#2-latency-test)
  - [3. Full Path Test](#3-full-path-test)
- [Validation Checklist](#validation-checklist)
  - [HQ Site](#hq-site)
  - [Remote Sites](#remote-sites)
  - [Performance](#performance)

## Test Environment Architecture

```mermaid
graph TB
    subgraph Internet
        inet[Internet]
    end

    subgraph HQ[HQ Site - 10.83.40.0/24]
        pa440_hq[PA-440]
        esxi_hq[ESXi]
        wg_hq[WireGuard VM]
        subgraph HQ_Network[Internal Network]
            hq_net[10.83.40.0/24]
        end
    end

    subgraph Site1[Site 1 - 10.83.10.0/24]
        pa440_1[PA-440]
        esxi_1[ESXi]
        wg_1[WireGuard VM]
        subgraph Site1_Network[Internal Network]
            site1_net[10.83.10.0/24]
        end
    end

    subgraph Site2[Site 2 - 10.83.20.0/24]
        pa440_2[PA-440]
        esxi_2[ESXi]
        wg_2[WireGuard VM]
        subgraph Site2_Network[Internal Network]
            site2_net[10.83.20.0/24]
        end
    end

    subgraph Site3[Site 3 - 10.83.30.0/24]
        pa440_3[PA-440]
        esxi_3[ESXi]
        wg_3[WireGuard VM]
        subgraph Site3_Network[Internal Network]
            site3_net[10.83.30.0/24]
        end
    end

    inet --- pa440_hq
    pa440_1 -.-> pa440_hq
    pa440_2 -.-> pa440_hq
    pa440_3 -.-> pa440_hq

    pa440_hq --- esxi_hq
    pa440_1 --- esxi_1
    pa440_2 --- esxi_2
    pa440_3 --- esxi_3

    esxi_hq --- wg_hq
    esxi_1 --- wg_1
    esxi_2 --- wg_2
    esxi_3 --- wg_3

    wg_hq --- hq_net
    wg_1 --- site1_net
    wg_2 --- site2_net
    wg_3 --- site3_net

    classDef internet fill:#f9f,stroke:#333,stroke-width:2px;
    classDef firewall fill:#f96,stroke:#333,stroke-width:2px;
    classDef esxi fill:#9cf,stroke:#333,stroke-width:2px;
    classDef wireguard fill:#9f9,stroke:#333,stroke-width:2px;
    classDef network fill:#fff,stroke:#333,stroke-width:1px;

    class inet internet;
    class pa440_hq,pa440_1,pa440_2,pa440_3 firewall;
    class esxi_hq,esxi_1,esxi_2,esxi_3 esxi;
    class wg_hq,wg_1,wg_2,wg_3 wireguard;
    class hq_net,site1_net,site2_net,site3_net network;
```

## Network Flow

```mermaid
sequenceDiagram
    participant Internet
    participant HQ_PA440 as HQ PA-440
    participant HQ_WG as HQ WireGuard
    participant Site_WG as Site WireGuard
    participant Site_Net as Site Network

    Site_Net->>Site_WG: Internal Traffic
    Site_WG->>HQ_WG: WireGuard Tunnel
    HQ_WG->>HQ_PA440: Route via DMZ
    HQ_PA440->>Internet: NAT to Internet
    Internet-->>HQ_PA440: Response
    HQ_PA440-->>HQ_WG: Route to WireGuard
    HQ_WG-->>Site_WG: WireGuard Tunnel
    Site_WG-->>Site_Net: Deliver to Internal
```

## Validation Steps

### 1. Internet Gateway (HQ)

```mermaid
graph LR
    A[Start] --> B{Check Internet}
    B -->|Success| C{Check NAT}
    B -->|Fail| B1[Verify WAN]
    C -->|Success| D{Check Routing}
    C -->|Fail| C1[Check NAT Rules]
    D -->|Success| E[Ready]
    D -->|Fail| D1[Verify Routes]

    style A fill:#f9f
    style E fill:#9f9
    style B1 fill:#f96
    style C1 fill:#f96
    style D1 fill:#f96
```

Commands:
```bash
# Internet Connectivity
ping -c 4 8.8.8.8

# NAT Verification
sudo tcpdump -i any port 53

# Routing Check
ip route show
traceroute 8.8.8.8
```

### 2. WireGuard Tunnels

```mermaid
graph LR
    A[Start] --> B{Check Tunnels}
    B -->|Success| C{Check Peers}
    B -->|Fail| B1[Verify Service]
    C -->|Success| D{Check Handshake}
    C -->|Fail| C1[Check Keys]
    D -->|Success| E[Ready]
    D -->|Fail| D1[Check Endpoints]

    style A fill:#f9f
    style E fill:#9f9
    style B1 fill:#f96
    style C1 fill:#f96
    style D1 fill:#f96
```

Commands:
```bash
# Check WireGuard Status
sudo wg show

# Verify Connectivity
ping -c 4 10.83.40.254  # To HQ
ping -c 4 10.83.10.254  # To Site 1
ping -c 4 10.83.20.254  # To Site 2
ping -c 4 10.83.30.254  # To Site 3

# Monitor Traffic
sudo tcpdump -i wg0 -n
```

### 3. Inter-Site Communication

```mermaid
graph LR
    A[Start] --> B{Site to Site}
    B -->|Success| C{Check Routes}
    B -->|Fail| B1[Verify WireGuard]
    C -->|Success| D{Check Policies}
    C -->|Fail| C1[Check Routing]
    D -->|Success| E[Ready]
    D -->|Fail| D1[Verify PA-440]

    style A fill:#f9f
    style E fill:#9f9
    style B1 fill:#f96
    style C1 fill:#f96
    style D1 fill:#f96
```

Commands:
```bash
# Test Site Connectivity
for site in 10 20 30 40; do
    echo "Testing 10.83.${site}.0/24"
    ping -c 4 10.83.${site}.254
done

# Trace Routes
for site in 10 20 30 40; do
    echo "Tracing to 10.83.${site}.0/24"
    traceroute 10.83.${site}.254
done
```

## Performance Testing

### 1. Bandwidth Test
```bash
# On Server (HQ)
iperf3 -s

# On Clients (Remote Sites)
iperf3 -c 10.83.40.254 -t 30
```

### 2. Latency Test
```bash
# From Each Site
for site in 10 20 30 40; do
    echo "Testing latency to 10.83.${site}.254"
    ping -c 100 10.83.${site}.254 | tail -1
done
```

### 3. Full Path Test
```bash
# From Remote Sites
mtr -n -c 100 8.8.8.8
mtr -n -c 100 10.83.40.254
```

## Validation Checklist

### HQ Site
- [ ] Internet access (ping 8.8.8.8)
- [ ] NAT working (tcpdump shows translated traffic)
- [ ] WireGuard tunnels established (wg show)
- [ ] Routes to all sites present (ip route show)

### Remote Sites
- [ ] WireGuard tunnel to HQ (ping 10.83.40.254)
- [ ] Internet access through HQ (ping 8.8.8.8)
- [ ] Inter-site connectivity (ping other sites)
- [ ] Default route via WireGuard (ip route show)

### Performance
- [ ] Latency < 100ms to HQ
- [ ] Bandwidth > 10Mbps
- [ ] No packet loss
- [ ] Stable tunnels (wg show)
