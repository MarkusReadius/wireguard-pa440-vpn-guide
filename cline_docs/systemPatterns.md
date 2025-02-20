# System Architecture and Design Patterns

## Network Architecture
```mermaid
graph TB
    subgraph Internet
        inet[Internet]
    end

    subgraph HQ[HQ - 10.83.40.0/24]
        pa440_hq[PA-440]
        wg_hq[WireGuard VM]
        internal_hq[Internal Network]
    end

    subgraph Site1[Site 1 - 10.83.10.0/24]
        pa440_1[PA-440]
        wg_1[WireGuard VM]
        internal_1[Internal Network]
    end

    subgraph Site2[Site 2 - 10.83.20.0/24]
        pa440_2[PA-440]
        wg_2[WireGuard VM]
        internal_2[Internal Network]
    end

    subgraph Site3[Site 3 - 10.83.30.0/24]
        pa440_3[PA-440]
        wg_3[WireGuard VM]
        internal_3[Internal Network]
    end

    inet --- pa440_hq
    inet --- pa440_1
    inet --- pa440_2
    inet --- pa440_3

    pa440_hq --- wg_hq
    pa440_1 --- wg_1
    pa440_2 --- wg_2
    pa440_3 --- wg_3

    wg_hq --- internal_hq
    wg_1 --- internal_1
    wg_2 --- internal_2
    wg_3 --- internal_3
```

## Key Design Patterns

### 1. Network Segmentation
- Each site maintains its own /24 network
- Clear separation between WireGuard and internal networks
- Standardized addressing scheme across all sites

### 2. Security Architecture
- PA-440 firewalls as primary security boundary
- WireGuard for encrypted site-to-site tunnels
- Isolated VM networks for WireGuard servers

### 3. Virtualization Pattern
- ESXi-hosted Ubuntu VMs
- Dedicated network interfaces for:
  - WireGuard tunnel traffic
  - Internal network communication
  - Management access

### 4. Routing Architecture
- Full mesh WireGuard topology
- Static routes for known networks
- NAT handling at PA-440 boundaries

### 5. Testing Pattern
```mermaid
graph TB
    subgraph TestEnv[Test Environment]
        internet[Internet]
        pa440_main[Internet-Connected PA-440]
        subgraph IsolatedNetwork[Isolated Network]
            pa440_2[PA-440 Site 2]
            pa440_3[PA-440 Site 3]
            pa440_hq[PA-440 HQ]
        end
    end

    internet --- pa440_main
    pa440_main --- pa440_2
    pa440_main --- pa440_3
    pa440_main --- pa440_hq
```

## Implementation Patterns

### 1. WireGuard Configuration
- Standardized config file structure
- Consistent key management
- Unified routing tables

### 2. PA-440 Configuration
- Standardized security policies
- Consistent NAT rules
- Uniform routing configuration

### 3. Monitoring Pattern
- Health checks between sites
- Bandwidth monitoring
- Latency tracking
- Connection state monitoring

### 4. Backup Pattern
- Configuration backups
- Key backups
- Recovery procedures

### 5. Documentation Pattern
- Step-by-step guides
- Configuration templates
- Troubleshooting flowcharts
- Validation checklists
