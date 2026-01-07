# MikroTik Router Network Documentation

**Date:** [DATE]  
**Configuration Version:** CAPsMAN Controller with CAP AX Devices  
**System Identity:** router-main  
**Hardware:** MikroTik Router + CAP AX devices

## Network Architecture Overview

![Network Diagram](network-diagram.png)

*Note: Convert `network-diagram-sanitized.mermaid` to PNG using https://mermaid.live or your preferred Mermaid renderer*

## Executive Summary

This network implements a **CAPsMAN-based WiFi architecture** with centralized management, comprehensive VLAN segmentation, and backhaul for CAP AX devices. A well-crafted home network with advanced features like band steering, load balancing, and zero-trust security policies.

## Hardware Configuration

### Main Router (Controller)
- **Model:** MikroTik Router with WiFi 6 (e.g., Chateau, hAP ax³, etc.)
- **Role:** CAPsMAN Controller + Local WiFi
- **Primary WAN:** ether5 (2.5G Ethernet)
- **Backup WAN:** Available (e.g., LTE/5G modem)
- **Management IP:** 192.168.254.254

### CAP AX Devices (Managed)
- **Roof CAP:** cap-roof (Backhaul connection)
- **Basement CAP:** cap-bsmnt (Backhaul connection)
- **Management:** DHCP from 192.168.254.0/24
- **Discovery:** Automatic via CAPsMAN

### Port Assignment (Main Router)
| Port | Speed | Device | VLAN | Purpose |
|------|-------|---------|------|---------|
| **ether1** | **1G** | **Backhaul Adapter** | **Trunk** | **CAP backhaul (all VLANs tagged)** |
| ether2 | 1G | Device 1 | 2 (untagged) | Infrastructure device |
| ether3 | 1G | Device 2 | 2 (untagged) | Infrastructure device |
| ether4 | 1G | Device 3 | 2 (untagged) | Infrastructure device |
| **ether5** | **2.5G** | **WAN** | **WAN** | **Primary Internet** |

### CAP AX Device Ports
| Device | Port | Connection | Status | Purpose |
|--------|------|------------|--------|---------|
| Roof CAP | ether1 | Backhaul Adapter | Trunk | Backhaul (all VLANs tagged) |
| Roof CAP | ether2 | — | **DISABLED** | Security (unused port disabled) |
| Basement CAP | ether1 | Backhaul Adapter | Trunk | Backhaul (all VLANs tagged) |
| Basement CAP | ether2 | — | **DISABLED** | Security (unused port disabled) |

## VLAN Architecture

### Network Segmentation Strategy

| VLAN | Name | Network | Gateway | Purpose | DHCP Lease |
|------|------|---------|---------|---------|------------|
| **1** | Management | `192.168.254.0/24` | `.254.254` | Admin & CAPsMAN | Unlimited |
| **2** | Infrastructure | `192.168.255.0/24` | `.255.1` | Smart home + compute | Unlimited |
| **3** | Data | `172.16.250.0/23` | `.250.1` | User devices | 365 days |
| **4** | Guest | `172.16.252.0/23` | `.252.1` | Isolated guest access | 7 days |

### DHCP Configuration

#### DHCP Pools
```
VLAN 1 (Management):    192.168.254.10 - 192.168.254.240 (230 addresses)
VLAN 2 (Infrastructure): 192.168.255.10 - 192.168.255.240 (230 addresses)
VLAN 3 (Data):          172.16.250.10 - 172.16.251.240 (486 addresses)
VLAN 4 (Guest):         172.16.252.10 - 172.16.253.240 (486 addresses)
```

#### DNS Servers
- **Primary:** 8.8.8.8, 8.8.4.4 (Google)
- **Fallback:** 1.1.1.1 (Cloudflare)

## Wireless Network Configuration

### CAPsMAN Architecture

#### Management
- **Controller:** Main router (192.168.254.254)
- **Management Interface:** VLAN 1 (192.168.254.0/24)
- **Discovery:** Automatic via backhaul
- **Provisioning:** Auto-provisioning for local and remote radios

#### Physical Radios
- **Main Router:** wifi1 (5GHz), wifi2 (2.4GHz)
- **Roof CAP:** wifi1 (5GHz), wifi2 (2.4GHz)
- **Basement CAP:** wifi1 (5GHz), wifi2 (2.4GHz)

#### Virtual SSIDs (5 Networks)

| SSID | Band | VLAN | Visibility | Purpose |
|------|------|------|------------|---------|
| `network-mgmt` | 5GHz | 1 | Hidden | Management access |
| `network-infra` | 2.4GHz | 2 | Hidden | Infrastructure devices |
| `network-data` | 2.4GHz | 3 | Visible | Primary user network |
| `network-alterdata` | 5GHz | 3 | Visible | Alternative user network |
| `network-guest` | 2.4GHz | 4 | Visible | Guest access |

#### Channel Assignment (2.4GHz - Non-overlapping)
| Location | Channel | Frequency |
|----------|---------|-----------|
| Roof CAP | 1 | 2412 MHz |
| Main Router | 6 | 2437 MHz |
| Basement CAP | 11 | 2462 MHz |

#### TX Power Configuration
- **2.4GHz Roof CAP:** 15 dBm (standard)
- **2.4GHz Main Router:** 15 dBm (standard)
- **2.4GHz Basement CAP:** 20 dBm (boosted for concrete penetration)
- **5GHz (all APs):** 20 dBm (boosted for indoor penetration)

#### WiFi Steering Configuration
- **Band Steering:** Automatic 2.4GHz ↔ 5GHz steering
- **Load Balancing:** Client distribution across CAPs
- **Neighbor Groups:** Auto-discovered by SSID
- **Roaming:** Seamless handoff between access points
- **RSSI Enforcement:** Band-specific (5GHz: -72 dBm, 2.4GHz: -75 dBm)

#### Security Configuration
- **Management:** WPA3-PSK only (highest security)
- **Infrastructure:** WPA2-PSK/WPA3-PSK mixed mode
- **Data Networks:** WPA2-PSK/WPA3-PSK mixed mode
- **Guest:** WPA2-PSK/WPA3-PSK mixed mode
- **Hidden Networks:** Management and Infrastructure

## Advanced Failover System (Planned)

*Note: Failover configuration planned for future implementation*

### Dual WAN Configuration (Hardware Ready)
- **Primary:** ISP via ether5 (2.5G)
- **Backup:** LTE/5G modem (available but not configured)
- **Future:** Policy-based routing with health monitoring

## Security Architecture

### Zero-Trust Network Policies

#### Network Isolation Rules
- **Guest → All Private Networks:** BLOCKED
- **Data → Infrastructure/Management:** BLOCKED  
- **Data → Guest:** BLOCKED
- **Management → All VLANs:** ALLOWED (admin access)
- **Infrastructure → Internet:** ALLOWED (updates)

#### Service Security
- **WinBox:** 192.168.254.0/24 only  
- **SSH:** 192.168.254.0/24 only
- **HTTPS:** 192.168.254.0/24 only (TLS 1.2, self-signed certificate)
- **MAC-Winbox:** mgmt-only interface list (vlan1 only)
- **MAC-Telnet:** mgmt-only interface list (vlan1 only)
- **Neighbor Discovery:** lan-interfaces (all VLANs)
- **Disabled:** HTTP, API, Telnet, FTP

#### Interface Lists
| List | Members | Purpose |
|------|---------|---------|
| **wan-interfaces** | ether5 | WAN routing and NAT |
| **lan-interfaces** | br1, vlan1, vlan2, vlan3, vlan4 | Firewall rules (DHCP, DNS, ICMP) |
| **mgmt-only** | vlan1 | Restricted access (MAC-server, sensitive services) |

#### Client Isolation (L2)
- **Guest Network:** Enabled (prevents guest-to-guest communication)
- **Infrastructure Network:** Enabled (prevents IoT device-to-device communication)
- **Data Network:** Disabled (allows device communication for media sharing)

#### DNS Security
- **All VLANs:** DNS queries allowed to router (UDP/TCP 53)
- **Guest Network:** DNS redirect to router (prevents bypass, captive portal ready)

### Firewall Configuration
- **Default Policy:** DROP (zero-trust)
- **Established/Related:** ACCEPT
- **Invalid Connections:** DROP (early in chain)
- **Anti-Spoofing:** Strict reverse path filtering, private src from WAN blocked
- **Logging:** Key drop rules logged (INPUT-DROP, FWD-DROP, GUEST-PRIV)

#### Silent Drop Rules (no logging - reduces noise)
| Rule | Interface | Traffic | Purpose |
|------|-----------|---------|---------|
| WAN noise | wan-interfaces | All | Internet scanners/bots |
| IoT discovery | vlan2 | UDP 6667 | Device discovery protocols |
| Spotify discovery | vlan3 | UDP 57621 | Spotify Connect discovery |
| DHCP discover | all | UDP 68→67 broadcast | Client IP requests |
| NetBIOS | lan-interfaces | UDP 137 | Windows/Mac network discovery |

### Logging Configuration
- **Main Memory:** 500 lines (reduced from 1000 for efficiency)
- **WiFi Memory:** 200 lines (wireless,!debug)
- **Security Disk:** `security.x.txt` - firewall audit trail (500×3 files)
- **System Disk:** `system.x.txt` - dhcp/caps/script events,!debug (500×2 files)
- **WiFi Disk:** `wifi-logs.x.txt` - wireless events,!debug
- **Best Practice:** Debug excluded from all rules (production, not troubleshooting)

## Configuration Management

### Configuration Sequence
Apply configurations in this exact order (after router reset):
1. `router-base-sanitized.rsc` - Core router & CAPsMAN setup
2. `router-base-mtu-sanitized.rsc` - MTU optimization
3. `router-base-steering-sanitized.rsc` - WiFi steering (auto-discovers neighbor groups)
4. `router-firewall-sanitized.rsc` - Security rules (replaces base config's open firewall)
5. `router-logging-sanitized.rsc` - Logging optimization (memory reduction, disk audit)

*Note: WAN failover config planned for future implementation*

### CAP Device Configuration
- `cap-device-sanitized.rsc` - Generic CAP template (customize for each location)

## Troubleshooting Guide (Cheat Sheet)

### CAPsMAN Issues
```routeros
# Check CAPsMAN status
/interface wifi capsman print
/interface wifi capsman remote-cap print

# CAPsMAN logs
/log print where topics~"caps"

# Interface status
/interface wifi print detail

# Provisioning rules
/interface wifi provisioning print
```

### Firewall Issues
```routeros
# View all filter rules with rule numbers
/ip firewall filter print

# Check rule statistics (packet/byte counts)
/ip firewall filter print stats

# View firewall logs (INPUT-DROP, FWD-DROP, GUEST-PRIV)
/log print where message~"DROP"

# Check rule order for specific chain
/ip firewall filter print where chain=forward

# Verify infra rules are BEFORE default deny
# Rule "infra > internet allow" should have lower number than "FWD-DROP"
```

### Network Connectivity
```routeros
# Test VLAN connectivity
/ping 192.168.254.254 count=3  # Management
/ping 192.168.255.1 count=3    # Infrastructure
/ping 172.16.250.1 count=3     # Data
/ping 172.16.252.1 count=3     # Guest

# Test isolation (should fail)
/tool ping address=192.168.255.1 interface=vlan3  # data→infra

# Check DHCP leases
/ip dhcp-server lease print
```

### Performance Monitoring
```routeros
# WiFi performance
/interface wifi monitor wifi1
/interface wifi registration-table print

# System health
/system resource print
/interface print stats

# WAN status
/ip route print where active
```

## Backup and Maintenance

### Regular Backups
```routeros
# Export configuration
/export compact file=backup-$(date)

# Create system backup
/system backup save name=system-backup-$(date)
```

### Health Monitoring
```routeros
# Check system health
/system health print

# Monitor logs
/log print

# Check disk usage
/system resource print

# View traffic and resource graphs via WebFig
# Access: https://192.168.254.254/graphs
# Graphing enabled for all interfaces and system resources
/tool graphing interface print
/tool graphing resource print
```

## Resources and Inspiration

This configuration was developed using the following resources:

### **Primary Inspiration:**
- **MikroTik Forum Discussion**: [Chateau LTE12 and self-managed WiFi with CAPsMAN](https://forum.mikrotik.com/t/chateau-lte12-and-self-managed-wifi-with-capsman/176219) - The working forum example that heavily inspired this configuration approach

### **Official Documentation:**
- **MikroTik Documentation**: https://help.mikrotik.com/docs/
- **CAPsMAN Guide**: https://help.mikrotik.com/docs/display/ROS/CAPsMAN
- **WiFi Configuration**: https://help.mikrotik.com/docs/display/ROS/WiFi
- **RouterOS Firewall**: https://help.mikrotik.com/docs/display/ROS/Filter
- **VLAN Configuration**: https://help.mikrotik.com/docs/display/ROS/Bridging+and+Switching

### **Community Resources:**
- **MikroTik Community Forum**: https://forum.mikrotik.com/
- **MikroTik Training**: https://mikrotik.com/training
- **RouterOS Downloads**: https://mikrotik.com/download

### **Technical References:**
- **RouterOS v7 WiFi**: https://help.mikrotik.com/docs/display/ROS/WiFi
- **Policy-Based Routing**: https://help.mikrotik.com/docs/display/ROS/Policy+Based+Routing
- **Bridge VLAN Filtering**: https://help.mikrotik.com/docs/display/ROS/Bridge+VLAN+Filtering

---

*This documentation reflects the current network configuration. The original configuration was heavily inspired by the MikroTik community forum discussion linked above.*


